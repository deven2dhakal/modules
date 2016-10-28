# /etc/puppet/modules/global/manifests/rhel6patching.pp

class global::rhel6patching {
  $bashPackages = [ 'bash', 'bash-doc' ]

  package { $bashPackages:
    ensure => latest,
    notify => Exec['refresh_ldconfig'];
  }

  # glibc patch
  $glibcPackages = [ 'glibc', 'glibc-common', 'glibc-devel', 'glibc-headers',
    'glibc-static', 'glibc-utils' ]

  package { $glibcPackages:
    ensure  => latest,
    notify  => Exec['refresh_ldconfig', 'patch_restart_sshd'];
  }

  exec { 'patch_restart_sshd':
    command     => '/sbin/service sshd restart',
    refreshonly => true
  }

  exec { 'refresh_ldconfig':
    command     => '/sbin/ldconfig',
    refreshonly => true
  }
}
