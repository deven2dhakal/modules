# /etc/puppet/modules/global/manifests/yumrepos.pp

# Various global config files for Linux hosts
class global::yumrepos {
  case $::operatingsystem {
    'RedHat': {
      include global::rhel_yumrepos
    }
    'CentOS': {
      include global::centos_yumrepos
    }
    default: {}
  }

  yumrepo {
    'dotomi-syseng':
      descr    => 'dotomi-syseng',
      baseurl  => "${global::yumRepoPath}/int/dotomi-syseng/${::lsbmajdistrelease}",
      enabled  => 1,
      gpgcheck => 0;
    'dotomi-neteng':
      descr    => 'dotomi-neteng',
      baseurl  => "${global::yumRepoPath}/int/dotomi-neteng/${::lsbmajdistrelease}",
      enabled  => 1,
      gpgcheck => 0;
  }

  file {
    '/etc/yum.conf':
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => "puppet:///modules/global/etc/yum.conf-${::operatingsystem}-${::lsbmajdistrelease}";
  }
}
