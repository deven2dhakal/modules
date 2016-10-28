# modules/global/manifests/ntp.pp

class global::ntp {
  package { 'ntp':
    ensure => present;
  }
  if ($::is_docker == 'false') {
    service { 'ntpd':
      ensure     => 'running',
      enable     => true,
      hasrestart => true,
      hasstatus  => true,
      subscribe  => [
        File['/etc/ntp.conf'],
      ],
    }
  }
  # IRIS monitors time so this is to allow for that
  $_nagiosServers = [ 'core101.dev.wl.mon.vclk.net',
    'core101.qa.wl.mon.vclk.net', 'core101.sj2.mon.vclk.net',
    'monitor.vclk.net', 'nagios101.sj2.vclk.net',
    'nagios101.wl.vclk.net', 'stage101.sj2.mon.vclk.net' ]

  file { '/etc/ntp.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('global/etc/ntp.conf.erb');
  }
}
