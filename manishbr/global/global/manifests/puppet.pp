#
#/etc/puppet/modules/global/manifests/puppet.pp

# Various global config files for Linux hosts
class global::puppet {
  # YUM repositories that should always be available.
  yumrepo {
    'puppet-dependencies':
      descr     => 'puppet-dependencies',
      baseurl   => "${global::yumRepoPath}/ext/puppet/${::lsbmajdistrelease}/dependencies/\$basearch",
      enabled   => 1,
      gpgkey    => "${global::yumRepoPath}/ext/puppet/RPM-GPG-KEY-puppetlabs",
      # assumeyes => 1,
      gpgcheck  => 1;
    'puppet-products':
      descr     => 'puppet-products',
      baseurl   => "${global::yumRepoPath}/ext/puppet/${::lsbmajdistrelease}/products/\$basearch",
      enabled   => 1,
      gpgkey    => "${global::yumRepoPath}/ext/puppet/RPM-GPG-KEY-reductive",
      # assumeyes => 1,
      gpgcheck  => 1;
  }

  unless str2bool($::is_docker) {
    # puppet
    service { 'puppet':
      ensure     => running,
      hasrestart => true,
      enable     => true;
    }
  }

  file {
    '/etc/sysconfig/puppet':
      owner  => 'root',
      group  => 'root',
      mode   => '0444',
      source => 'puppet:///modules/global/etc/sysconfig/puppet';

    '/usr/local/sbin/fixStalePuppet.sh':
      owner  => 'root',
      group  => 'root',
      mode   => '0555',
      source => 'puppet:///modules/global/usr/local/sbin/fixStalePuppet.sh';

    '/var/log/puppet':
      ensure => 'directory',
      mode   => '0755';
  }

  # Setting this to run hourly which is safer because if the stale YAML file
  # is lingering for that long it means that most definitely one puppet run
  # did not complete.
  if $::fqdn == 'dtord01qar01d.dc.dotomi.net' {
    cron { 'restart_stale_puppet':
      ensure  => present,
      command => '/usr/local/sbin/fixStalePuppet.sh',
      user    => 'root',
      special => 'hourly',
      require => File['/usr/local/sbin/fixStalePuppet.sh'];
    }
  }

  # With packages versionlocked, this can probably go away. Leaving it for now...
  # Here for whenever we need to upgrade puppet
  $desired_puppet_version = '3.5.1'
  exec { 'upgradepuppet':
    command => "yum clean all; yum -y remove puppet; yum -y install puppet-${desired_puppet_version}; service puppet restart",
    unless  => "rpm -q puppet-${desired_puppet_version}",
    require => Yumrepo['puppet-products', 'puppet-dependencies'];
  }

  if $::lsbmajdistrelease == 5 {
    package { 'ruby-augeas':
      ensure => latest;
    }
  }
}
