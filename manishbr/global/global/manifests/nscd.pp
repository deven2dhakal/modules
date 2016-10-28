# /etc/puppet/modules/global/manifests/nscd.pp

# This class is meant to be available for any host which can benefit from it.
class global::nscd {
  file { '/etc/nscd.conf':
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/global/etc/nscd.conf';
  }

  package { 'nscd':
    ensure => installed;
  }

  service { 'nscd':
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
    subscribe  => File['/etc/nscd.conf'];
  }
}
