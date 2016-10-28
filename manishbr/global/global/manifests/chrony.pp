# modules/global/manifests/chrony.pp

class global::chrony {
  service { 'ntpd':
    ensure => stopped;
  }

  package { 'chrony':
    ensure => present;
  }

  service { 'chronyd':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true;
  }

  file { '/etc/chrony.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('global/etc/chrony.conf.erb'),
    notify  => Service['chronyd'];
  }
}
