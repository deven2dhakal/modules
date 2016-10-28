# Enable patching of hosts
#
class global::patching {

  yum::repo {
    'OS':
      path  => "/repos/${::patch_version}/OS/${::operatingsystem}/\$releasever/\$basearch/",
      descr => "CentOS\$releasever - \$basearch";
    'Emergency':
      path  => "/repos/${::patch_version}/Emergency/${::operatingsystem}/\$releasever/\$basearch/",
      descr => "Emergency Patches\$releasever - \$basearch";
    'SysEng':
      path  => "/repos/${::patch_version}/SysEng/\$releasever/\$basearch/",
      descr => "SysEng Packages (Puppet, collectd, etc) \$releasever - \$basearch";
  }

  include yum::client

  class {'yum::upgrade':
    enablerepos => [ 'Emergency', 'SysEng' ],
    require     => Class[Yum::Client]
  }

  # This should move back to global::puppet once IPA deployment is complete
  # Can't do it now due to the dependencies on yum::upgrade 

  # TODO: Manage puppet.conf via augeas to set server, etc

  # I'm really starting to miss hiera...
  case $::lsbmajdistrelease {
    '5': {
      $puppet_package = '0:puppet-3.5.1-1.el5.noarch'
      $facter_package = '1:facter-2.1.0-1.el5.x86_64'
      $hiera_package = '0:hiera-1.3.4-1.el5.noarch'
    }
    '6': {
      $puppet_package = '0:puppet-3.5.1-1.el6.noarch'
      $facter_package = '1:facter-2.4.4-1.el6.x86_64'
      $hiera_package = '0:hiera-1.3.4-1.el6.noarch'
    }
    '7': {
      $puppet_package = '0:puppet-3.5.1-1.el7.noarch'
      $facter_package = '1:facter-2.1.0-1.el7.x86_64'
      $hiera_package = '0:hiera-1.3.4-1.el7.noarch'
    }
  }

  # I think ensure_resources() would work well here, but it actually ends up
  # feeling less readable...
  yum::versionlock {$puppet_package: before => Class[Yum::Upgrade]}
  yum::versionlock {$facter_package: before => Class[Yum::Upgrade]}
  yum::versionlock {$hiera_package: before => Class[Yum::Upgrade]}

}
