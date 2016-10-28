# modules/global/manifests/init.pp

# PLEASE DO NOT MERGE CHANGES TO MASTER FOR ANYTHING IN GLOBAL UNTIL THERE IS
# SYSENG SIGN-OFF!  THANK YOU!
# Various global config files for Linux hosts
class global {
  # We don't want to hose systems
  if $::osfamily != 'RedHat' {
    fail('Puppet is not configured for this OS - bad things can happen so failing')
  }

  # We create the required repositories here and so the OPS servers don't
  # need to traverse the network
  $yumRepoPath = "http://${::dc}-yum.dc.dotomi.net" # Used for custom in-house repos
  $centosRepoPath = "http://${::dc}-centos.dc.dotomi.net" # Not used anymore
  $dellRepoPath = "http://${::dc}-dell.dc.dotomi.net" # Not used anymore

  # I'm not fond of this but for some apps in the environment even
  # nscd isn't a solution so this is a necessary evil.
  case $::vclk_product {
    # To call a parameterized class do class {'::class::name': param_name => value }
    'crm.gpforecast': {
      include gpforecast::hosts
    }

    'crm.gpso': {
      include gpso::hosts
    }

    'crm.qa': {
      case $::vclk_service {
        'crm.qa.qar', 'crm.qa.qas','crm.qa.ads': {
          include app_global::qa_hosts
        }
        default: {
          file { '/etc/hosts':
            owner   => 'root',
            group   => 'root',
            mode    => '0644',
            content => template('global/etc/hosts.erb');
          }
        }
      }
    }
    default: {
      file { '/etc/hosts':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('global/etc/hosts.erb');
      }
    }
  }

  # root password and other important users
  include global::users
  # YUM repositories
  include global::yumrepos
  # Puppet client
  include global::puppet
  # Other hardware specific items
  # adding is docker false to dell/global ipmi code
  if str2bool($::is_docker) == false and $::virtual == 'physical' {
    include global::ipmi
    # include global::cfgbmc
    # Manufacturer hardware specific items
    case $::manufacturer {
      'Dell Inc.': {
        # Dell DSU / OMSA repository and other tools
        # zbukhari-
        # Not sure we need is_docker is false because there's a
        # manufacturer Dell - guessing there's a reason - don't
        #know it but will leave this alone for now
        case $::vclk_service {
          default: { include ::dell }
          'crm.syseng.ops': {}
        }
      }
      default: { notice("global ${::manufacturer} is not supported.  Notify SYSENG.") }
    }
  }
  
  # Set version specific variables - this is crucial since lsb is not set
  #  until the lsb package is installed but operatingsystemmajrelease is.
  case $::operatingsystemmajrelease {
    5: {
      # if ($::is_docker == 'false') { include global::rhel5patching }
      $redhat_lsb_package = 'redhat-lsb'
    }
    6: {
      # if ($::is_docker == 'false') { include global::rhel6patching }
      $redhat_lsb_package = 'redhat-lsb-core'
    }
    7: {
      # if ($::is_docker == 'false') { include global::rhel7patching }
      $redhat_lsb_package = 'redhat-lsb-core'
    }
    default: {
      fail('This Red Hat variant is not supported.')
    }
  }

  unless str2bool($::is_docker) {
    # Logging has been moved here
    include global::logging
  }

  file {
    '/etc/sysctl.d':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
    '/etc/security/limits.d':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755';
  }

  # Packages that should be installed everywhere
  $packages = [ 'mtr', 'nmap', 'zsh', 'tzdata', 'curl', 'screen',
    $redhat_lsb_package ]
  package { $packages: ensure => 'installed' }

  # Packages requiring a specific repo
  $dotomi_neteng_packages = [ 'ifstat' ]
  package { $dotomi_neteng_packages:
    ensure  => 'installed',
    require => Yumrepo['dotomi-neteng'],
  }

  unless str2bool($::is_docker) {
    # mtr doesn't install with SUID but is useful
    file { '/usr/sbin/mtr':
        owner   => 'root',
        group   => 'root',
        mode    => '4755',
        require => Package['mtr'],
    }

    file { '/etc/updatedb.conf':
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
        source => 'puppet:///modules/global/etc/updatedb.conf';
    }

    ### sendmail ###
    package { 'sendmail':
        ensure => 'installed'
    }
  

    file { '/etc/mail/sendmail.cf':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  => 'puppet:///modules/global/etc/mail/sendmail.cf',
      require => Package['sendmail'];
    }

    ### Useful system files ###
    file {
      '/root/bin':
        ensure  => 'directory',
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        recurse => true,
        source  => 'puppet:///modules/global/root/bin';

      '/usr/local/bin/quiet-reboot':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => 'puppet:///modules/global/usr/local/bin/quiet-reboot';

      '/usr/local/sbin/bondMe.sh':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/global/usr/local/sbin/bondMe.sh';

      '/usr/local/sbin/useEm1.sh':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        source  => 'puppet:///modules/global/usr/local/sbin/useEm1.sh';
    }
  }

#  ### Remove postfix ###
#  if $operatingsystemrelease == '6.3' {
#    service { 'postfix':
#      enable => false,
#      ensure => stopped
#    }
#
#    package { 'postfix':
#      ensure => purged
#    }
#  }

  ### timezone ###
  # - Users need to set their local TZ as TZ in bash if they want - servers
  #   should always be UTC
  $tz = $::hostname ? {
    /^dtordopd.*$/ => 'US/Central',
    default        => 'UTC',
  }

  file {
    '/etc/localtime':
      ensure  => symlink,
      replace => true,
      target  => "/usr/share/zoneinfo/${tz}";
    '/etc/sysconfig/clock':
      owner  => 'root',
      group  => 'root',
      mode   => '0644',
      source => 'puppet:///modules/global/etc/sysconfig/clock';
  }

  # Clean up old shiz
  $oldrootbinremove = ['/root/bin/populatedtp.sh',
    '/root/bin/freeOmsaSemaphores.sh', '/root/bin/omTweaks.sh',
    '/root/bin/renameHost.sh', '/root/bin/fixCstates.sh',
    '/root/bin/quiet-reboot.sh']
  file { $oldrootbinremove:
    ensure  => 'absent',
  }

  # Useful hardware specific file(s)
  if $::hostname =~ /lvs/ {
    file { '/sbin/ifup-local':
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => 'puppet:///modules/global/sbin/ifup-local';
    }
  }

  # Things which should not be done on ops boxes
  unless $::hostname =~ /^dt\D+\d+ops\d+\D$/ {
    case $::dc {
      'ams','ams5': {
        $_OPSServers = [ '10.26.0.50', '10.130.0.50', '10.110.0.50',
          '10.30.0.50' ]
      }
      'iad','dc6': {
        $_OPSServers = [ '10.130.0.50', '10.110.0.50', '10.30.0.50',
          '10.26.0.50' ]
      }
      'sjc','sj2','wl': {
        $_OPSServers = [ '10.30.0.50', '10.110.0.50', '10.130.0.50',
          '10.26.0.50' ]
      }
      default: {
        $_OPSServers = [ '10.110.0.50', '10.130.0.50', '10.30.0.50',
          '10.26.0.50' ]
      }
    }

    # Docker manages its own resolv.conf
    unless str2bool($::is_docker) {
      file { '/etc/resolv.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('global/etc/resolv.conf.erb');
      }
    }

    ### time ###
    # IRIS monitors time so this is to allow for that
    $_nagiosServers = [ 'core101.dev.wl.mon.vclk.net',
      'core101.qa.wl.mon.vclk.net', 'core101.sj2.mon.vclk.net',
      'monitor.vclk.net', 'nagios101.sj2.vclk.net',
      'nagios101.wl.vclk.net', 'stage101.sj2.mon.vclk.net' ]

    case $::lsbmajdistrelease {
      7: {
        include global::chrony
      }
      default: {
        include global::ntp
      }
    }
  }

  ### autofs ###
  package { 'autofs':
    ensure => installed;
  }

  service { 'autofs':
    ensure     => 'running',
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require => Package['autofs'];
  }

  if '@CNVR.NET' in $::krb5_principals {
    include access::ipaclient
  }
  if str2bool($::cnvr_patching) {
    include global::patching
  }
}
