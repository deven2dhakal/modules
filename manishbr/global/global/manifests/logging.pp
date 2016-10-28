# /etc/puppet/modules/global/manifests/logging.pp

# Various global config files for Linux hosts
class global::logging {
  # Set version specific variables - this is crucial since lsb is not set
  #  until the lsb package is installed but operatingsystemmajrelease is.
  case $::operatingsystemmajrelease {
    5: {
      $syslogd_filename = 'syslog.conf'
      $syslogd_name = 'syslog'
    }
    6: {
      $syslogd_filename = 'rsyslog.conf'
      $syslogd_name = 'rsyslog'
    }
    7: {
      $syslogd_filename = 'rsyslog.conf'
      $syslogd_name = 'rsyslog'
    }
    default: {
      fail('This Red Hat variant is not supported.')
    }
  }

  file { "/etc/${syslogd_filename}":
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Service[$syslogd_name],
    source  => "puppet:///modules/global/etc/${syslogd_filename}";
  }

  if $::operatingsystemmajrelease > 5 {
    file {
      '/etc/rsyslog.d':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        purge   => true,
        recurse => true;

      '/etc/rsyslog.d/splunk.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        notify  => Service[$syslogd_name],
        source  => 'puppet:///modules/global/etc/rsyslog.d/splunk.conf';
    }
  }

  service { $syslogd_name:
    ensure     => running,
    hasrestart => true;
  }
}
