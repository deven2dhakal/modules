class global::fusion_io {

  if ($::operatingsystem == 'CentOS') and ($::lsbmajdistrelease != 5) {
    if $::hostname == 'dtchi99gfs01d' or $::hostname =~ /^dt\D+\d+mem7[1-9]p$/ {
      case $::lsbmajdistrelease {
        7: {
          $fio_version        = '4.2.1'
          $iomemory_ver       = '3.10.0-229.el7.x86_64.x86_64'
          $irqbalance_restart = 'systemctl restart irqbalance.service'
          $fusion_io_pkgs     = [ 'fio-common','fio-preinstall','fio-sysvinit','fio-util',"iomemory-vsl4-${iomemory_ver}",'fio-firmware-fusion' ]
        }
        6: {
          $fio_version        = '4.1.1'
          $iomemory_ver       = '2.6.32-431.el6.x86_64'
          $irqbalance_restart = '/etc/init.d/irqbalance restart'
          $fusion_io_pkgs     = [ 'fio-common','fio-preinstall','fio-sysvinit','fio-util','libvsl',"iomemory-vsl4-${iomemory_ver}",'fio-firmware-dell_iodrive' ]
        }
        default: {
          notify{"$hostname is CentOS $::lsbmajdistrelease and not CentOS 6 or 7":}
        }
      }

      if $::provisioning_version >= 4 {
        file {
          '/etc/sysctl.d/94-fio.conf':
            owner  => 'root',
            group  => 'root',
            mode   => '0600',
            source => "puppet:///modules/global/etc/sysctl.d/94-fio.conf",
            notify => Exec['reload_sysctl'];
        }
      }
      yumrepo {
       'cnvr-fusionio':
          descr   => "Fusion IO CentOS ${::os_major} Repo",
          baseurl => "http://${::dc}-yum.dc.dotomi.net/int/cnvr-fusionio/${::os_major}/${fio_version}/",
          enabled  => 1,
          gpgcheck => 0;
      }
    }
  }
  else {
    yumrepo {
     'cnvr-fusionio':
        ensure  => 'absent';
    }
  }

  if ($::mass_storage_controller_0_vendor == 'Fusion-io' or $::mass_storage_controller_0_vendor == 'SanDisk') and ($::mass_storage_controller_0_device =~ /^ioMemory [A-Z]HHL/) {

    $fio_dev = 'fioa'

    package { $fusion_io_pkgs:  ensure => latest }

    #Update the firmware if packages after package  updated

    exec { 'fio-firmware-update':
      path        => "/usr/local/bin/:/bin/:/usr/sbin:/usr/bin/",
      command     => '/root/bin/fio-fwupdate.sh',
      subscribe   => Package['fio-firmware-fusion'],
      refreshonly => true;
     }

    #Append to the ioMemory-vsl4 config and  fioa block values stated below

    file_line {
      'iomemory-vsl4 conf':
        path => '/etc/modprobe.d/iomemory-vsl4.conf',
        line => 'options iomemory-vsl4 use_workqueue=3';
    }
    exec { 'update fioa queue':
      path    => "/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin",
      command => "echo noop > /sys/block/fioa/queue/scheduler,echo 0 > /sys/block/fioa/queue/rotational,
      echo 0 > /sys/block/fioa/queue/add_random,echo 1 > /sys/block/fioa/queue/rq_affinty,
      echo 4096 > /sys/block/fioa/queue/nr_requests",
      unless  => "cat /sys/block/fioa/queue/nr_requests | grep -q '4096'",
      require => File_line['iomemory-vsl4 conf'];
    }

    exec {
      #Modprobe To load the Fusion ioMemory VSL driver
      '/sbin/modprobe iomemory-vsl4':
        logoutput => on_failure,
        unless    => "/sbin/lsmod | /bin/grep -q '^iomemory_vsl4'",
        alias     => 'fusion-iomemory';

      #Restart IRQbalance
      "${irqbalance_restart}":
        subscribe   => Exec['/sbin/modprobe iomemory-vsl4'],
        refreshonly => true;

      #Format the FusionIO card after loading
      "/sbin/mkfs.ext4 -O ^has_journal /dev/${fio_dev}":
        unless    => "/sbin/tune2fs -l /dev/${fio_dev} | /bin/grep -q 'UUID'",
        require   => Exec["${irqbalance_restart}"];

    }
    #mount the fusion-io card
    global::fusion_io_mnt{'/mnt/FIO': device => $fio_dev}
  }
}
