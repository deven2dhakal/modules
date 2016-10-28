# /etc/puppet/modules/global/manifests/rhel5patching.pp

class global::rhel5patching {
  # bash patch - CVE-???
  $bashPackages = [ 'bash' ]

  package { $bashPackages:
    ensure => latest,
    notify => Exec['refresh_ldconfig'];
  }

  # glibc patch - CVE-???
  $glibcPackages = [ 'glibc', 'glibc-common', 'glibc-devel', 'glibc-headers',
      'glibc-utils' ]

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
