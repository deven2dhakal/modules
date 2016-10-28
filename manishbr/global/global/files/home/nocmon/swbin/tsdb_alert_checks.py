import sys
import datetime
import argparse
import os
import time
import urllib
import collections
import smtplib
import logging
import ConfigParser
from email.mime.text import MIMEText

class Alert_Check:

    CONFIG_PARAMS = ['name', 
                     'message', 
                     'tsdb_metric_name', 
                     'tsdb_tags', 
                     'lookback_period', 
                     'warning_threshold_value', 
                     'warning_threshold_count', 
                     'critical_threshold_value', 
                     'critical_threshold_count', 
                     'threshold_comparator', 
                     'metric_data_aggregator', 
                     'rate_indicator', 
                     'email_recipients']

    REQUIRED_CONFIG_PARAMS = ['name', 
                              'message', 
                              'tsdb_metric_name', 
                              'lookback_period', 
                              'warning_threshold_value', 
                              'threshold_comparator', 
                              'metric_data_aggregator', 
                              'rate_indicator']

    THRESHOLD_COMPARISON_OPERATORS = ['eq', 
                                      'neq', 
                                      'lt', 
                                      'le', 
                                      'gt', 
                                      'ge'] 

    def __init__(self):
        self.epoch_time = time.time()
        self.logger = self.initialize_logger()

    def initialize_logger(self):
        logger = logging.getLogger('Alert_Check')
        logger.setLevel(logging.INFO)
        ch = logging.StreamHandler()
        ch.setLevel(logging.INFO)
        formatter = logging.Formatter('%(asctime)s : %(name)s : %(levelname)s : %(message)s')
        ch.setFormatter(formatter)
        logger.addHandler(ch)
        return logger
        
    def get_timestamp_string(self):
        return self.alert_check_timestamp.isoformat()

    def log_info(self, msg):
        self.logger.info(msg)

    def log_warning(self, msg):
        self.logger.warning(msg)

    def log_error(self, msg):
        self.logger.error(msg)

    def init_commandline_parser(self):
        self.parser = argparse.ArgumentParser(description='TSDB metrics alerter.')
        self.parser.add_argument('-t', '--tsdb_host_port', required=True, help='TSDB host and port information in the form host:port')
        self.parser.add_argument('-c', '--configuration_file', required=True, help='Configuration file containing alert check specifications')
        self.parser.add_argument('-k', '--alertcheck_key', required=True, help='Key for a specific alert check to be executed. Specifying the value "all" will perform an alert check for ALL keys in the configuration file.')
        self.parser.add_argument('-d', '--dryRun', action='store_true', help='Perform a dry run only. Will parse the configuration file for an alert check and dump the alert check configuration and the action that would be taken')
        self.parser.add_argument('-v', '--verbose', action='store_true', required=False, help='Increase logging/verbosity level')

    def parse_commandline_arguments(self, args):
        self.parsed_commandline_arguments = self.parser.parse_args(args)
        self.tsdb = self.parsed_commandline_arguments.tsdb_host_port
        self.configuration_file = self.parsed_commandline_arguments.configuration_file
        self.alertcheck_key = self.parsed_commandline_arguments.alertcheck_key
        self.dryRun = self.parsed_commandline_arguments.dryRun
        self.verbose = self.parsed_commandline_arguments.verbose
        if self.verbose:
            self.logger.info("Using alertcheck_key = " + self.parsed_commandline_arguments.alertcheck_key)
            self.logger.info("Using configuration file = " + self.parsed_commandline_arguments.configuration_file)
            self.logger.info("Using tsdb host+port = " + self.parsed_commandline_arguments.tsdb_host_port)

    def parse_configuration_file(self):
        alert_configuration_filename = self.parsed_commandline_arguments.configuration_file
        if not (os.path.isfile(alert_configuration_filename)):
            self.log_error("Configuration file " + alert_configuration_filename + " does not exist or is not a file.")
            sys.exit(0)
        self.configuration = ConfigParser.ConfigParser()
        self.configuration.read(alert_configuration_filename)

    def validate_configuration_file(self):
        self.logger.info("Validating configuration file")
        for alertcheck_key in self.configuration.sections():
            self.log_info("Validating alert check: " + alertcheck_key)
            self.validate_single_alert(alertcheck_key)

    def validate_single_alert(self, alertcheck_key):
        self.alertcheck_options = dict()
        if not self.configuration.has_section(alertcheck_key):
            self.logger.error("Cannot find configuration/settings for " + alertcheck_key + ". Exiting....")
            sys.exit(4)
        for param in self.CONFIG_PARAMS:
            if self.configuration.has_option(alertcheck_key, param):
                param_value = self.configuration.get(alertcheck_key, param)
            else:
                continue
            self.alertcheck_options[param] = param_value
            #print param, '=', param_value
        for param in self.REQUIRED_CONFIG_PARAMS:
            if param not in self.alertcheck_options:
                self.log_warning(alertcheck_key + " missing value for " + param + ". Exiting....")
                sys.exit(4)
        if self.alertcheck_options['threshold_comparator'] not in self.THRESHOLD_COMPARISON_OPERATORS:
            self.log_warning(alertcheck_key + " has invalid value for 'threshold_comparator' = " + self.alert_check_options['threshold_comparator'] + ". Exiting....")
            return False
        return True

    def get_data_violations(self, metric_data, threshold, threshold_comparator):
        # metric_data consists of two-value tuples of the format (metric_timestamp and metric_value)
        violations = []
        if threshold_comparator == 'gt':
            violations = [x for x in metric_data if x[1] > float(threshold)]
        elif threshold_comparator == 'ge':
            violations = [x for x in metric_data if x[1] >= float(threshold)]
        elif threshold_comparator == 'lt':
            violations = [x for x in metric_data if x[1] < float(threshold)]
        elif threshold_comparator == 'le':
            violations = [x for x in metric_data if x[1] <= float(threshold)]
        elif threshold_comparator == 'eq':
            violations = [x for x in metric_data if x[1] == float(threshold)]
        elif threshold_comparator == 'ne':
            violations = [x for x in metric_data if x[1] != float(threshold)]
        else:
            self.log_error("Encountered unhandled threshold comparator - " + threshold_comparaotr + ". Exiting...")
            sys.exit(4)
        if self.verbose:
            self.log_info("Metric_data = " +  str(metric_data))
            self.log_info("Threshold = " + str(threshold))
            self.log_info("Threshold comparator = " + str(threshold_comparator))
            self.log_info("Violations = " +  str(violations))
        return violations

    def execute_alert_check(self, alertcheck_key):
        #self.log_info("Check name = " + str(alertcheck_key))
        querytime = self.epoch_time - int(self.alertcheck_options['lookback_period'])
        query_start_datetime = datetime.datetime.fromtimestamp(querytime)
        query_start_datetime_string = str(query_start_datetime.year) + '/' + \
                                      str(query_start_datetime.month) + '/' + \
                                      str(query_start_datetime.day) + '-' + \
                                      str(query_start_datetime.hour) + ':' + \
                                      str(query_start_datetime.minute) + ':' + \
                                      str(int(query_start_datetime.second))
        query = "http://" + self.tsdb + "/q?start=" + query_start_datetime_string
        query = query + '&m=' + self.alertcheck_options['metric_data_aggregator']
        if self.alertcheck_options['rate_indicator'] is not None and self.alertcheck_options['rate_indicator'].lower() == 'y':
            query = query + ':rate'
        query = query + ':' + self.alertcheck_options['tsdb_metric_name'] 
        if self.alertcheck_options['tsdb_tags'] is not None:
            query = query + urllib.quote('{') + self.alertcheck_options['tsdb_tags'] + urllib.quote('}') + '&ascii'
        self.alertcheck_options['query'] = query
        self.metrics_data = self.get_tsdb_metrics_data(query, querytime)
        self.metrics_data_count = len(self.metrics_data)
        self.critical_violation_count = 0
        self.warning_violation_count = 0
        if self.verbose:
            self.log_info("Check details = " + str(self.alertcheck_options))
            self.log_info("Time window start time = " + str(int(querytime)) + " = " + query_start_datetime_string)
            self.log_info("HTTP query = " + query)
            self.log_info("Metric data = " + str(self.metrics_data))
        if self.alertcheck_options['warning_threshold_value'] is not None:
            self.warning_violations = self.get_data_violations(self.metrics_data, self.alertcheck_options['warning_threshold_value'], self.alertcheck_options['threshold_comparator'])
            if len(self.warning_violations) > 0:
                self.warning_violation_count = len(self.warning_violations)
        if self.alertcheck_options['critical_threshold_value'] is not None:
            self.critical_violations = self.get_data_violations(self.metrics_data, self.alertcheck_options['critical_threshold_value'], self.alertcheck_options['threshold_comparator'])
            if len(self.critical_violations) > 0:
                self.critical_violation_count = len(self.critical_violations)
        alert_type = 0
        # alert_type = the type of exit code. Meaning of the various values are -
        # 0 = everything ok
        # 1 = we did not have any metric data. Probably system is down ?
        # 2 = warning threshold violation occured
        # 3 = critical threshold violation occurred
        if self.metrics_data_count == 0:
            alert_type = 1
            self.print_solarwinds_msg(alertcheck_key, alert_type)
        elif self.critical_violation_count >= int(self.alertcheck_options['critical_threshold_count']):
            alert_type = 3
            self.print_solarwinds_msg(alertcheck_key, alert_type)
        elif self.warning_violation_count >= int(self.alertcheck_options['warning_threshold_count']):
            alert_type = 2
            self.print_solarwinds_msg(alertcheck_key, alert_type)
        if self.verbose:
            print "metrics_data_count = " + str(self.metrics_data_count)
            print "warnings = " + str(self.warning_violation_count)
            print "violations = " + str(self.critical_violation_count)
        return alert_type

    def print_solarwinds_msg(self, alertcheck_key, alert_type):
        # Construct a message that will be parsed by Solarwinds
        if alert_type == 1:
            print "Message." + alertcheck_key + ": No metric data found for in TSDB. Check if metric data is being collected and/or if the target system is up/running/alive"
            print "Statistic.1"
        elif alert_type == 2:
            print "Message." + alertcheck_key + ": Encountered " + str(self.alertcheck_options['warning_threshold_count']) + " warning alert check violations."
            print "Statistic.2"
        elif alert_type == 3:
            print "Message." + alertcheck_key + ": Encountered " + str(self.alertcheck_options['critical_threshold_count']) + " critical alert check violations."
            print "Statistic.3"
        self.send_email(alertcheck_key, alert_type)
        self.log_info("Email sent....")

    def get_tsdb_metrics_data(self, query, query_start_datetime):
        # For the sake of brevity and compactnemss, we are doing things kludgily and infficiently. So here's what we are doing:
        # Read all the data returned from querying TSDB and filter out ONLY the lines whose metric stat time is greater than or equal to the querytime.
        # Then for each of those qualified lines, only extract the metric time and the metric value
        # The metric data line is made up of the following fields:
        # 1st field = metric_name
        # 2nd field = metric_timestamp
        # 3rd field = metric_value
        # 4th and subsequent fields = tag key/value pairs
        urlreader = urllib.urlopen(query)
        metrics_data = [(float(line.strip().split(' ')[1]), float(line.strip().split(' ')[2])) for line in urlreader.readlines() if line.strip().split(' ')[1] >= query_start_datetime]
        return metrics_data

    def send_email(self, alertcheck_key, alert_type):
        if alert_type != 0 and 'email_recipients' in self.alertcheck_options:
            msg = MIMEText(self.alertcheck_options['name'] + ".\n" + 
                           self.alertcheck_options['message'] + "\n\n" + 
                           "Warning threshold value = " + str(self.alertcheck_options['warning_threshold_value']) + "\n" +
                           "Warning threshold count = " + str(self.alertcheck_options['warning_threshold_count']) + "\n" +
                           "Count of warning violations = " + str(self.warning_violation_count) + "\n\n" +
                           "Critical threshold value = " + str(self.alertcheck_options['critical_threshold_value']) + "\n" +
                           "Critical threshold count = " + str(self.alertcheck_options['critical_threshold_count']) + "\n" +
                           "Count of critical violations = " + str(self.critical_violation_count) + "\n\n" +
                           "Alert check metrics data is as follows: " + "\n" + 
                           str(self.metrics_data) + "\n\n" + 
                           "Please validate TSDB using the URL below\n" + self.alertcheck_options['query'].replace('&ascii', '&autoreload=60') + "\n\n" )
            msg['Subject'] = alertcheck_key + " - " + self.alertcheck_options['name']
            msg['From'] = 'dtm_hadoop_admins@dotomi.com'
            msg['To'] = self.alertcheck_options['email_recipients'].split()[0]
            mail = smtplib.SMTP()
            mail.connect()
            mail.sendmail('dtm_hadoop_admins@dotomi.com', self.alertcheck_options['email_recipients'].split(), msg.as_string())

    def execute_all_alerts(self):
        self.logger.info("Executing all alert checks in configuration file")
        for alertcheck_key in self.configuration.sections():
            self.log_info("Executing alert check: " + alertcheck_key)
            self.validate_single_alert(alertcheck_key) 
            self.execute_alert_check(alertcheck_key)

def main(args):
    alert_check = Alert_Check()
    alert_check.init_commandline_parser()
    alert_check.parse_commandline_arguments(args[1:])
    alert_check.parse_configuration_file()
    if alert_check.dryRun:
        alert_check.validate_configuration_file()
        sys.exit(0)
    if alert_check.alertcheck_key == 'all':
        #alert_check.validate_configuration_file() 
        alert_check.execute_all_alerts()
    else:
        alert_check.validate_single_alert(alert_check.alertcheck_key) 
        exit_code = alert_check.execute_alert_check(alert_check.alertcheck_key)
        sys.exit(exit_code)

main(sys.argv)
