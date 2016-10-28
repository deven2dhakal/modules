# modules/global/manifests/ipmi.pp

class global::ipmi {
  $ipmi_packages = [ 'OpenIPMI' ]

  package { $ipmi_packages:
    ensure => installed;
  }

  # Technically I don't need this but it's a convenience
  service { 'ipmi':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => Package['OpenIPMI'];
  }

  exec {
    'load_ipmi_msghandler':
      command => 'true',
      # command => 'modprobe ipmi_msghandler',
      onlyif  => [ 'modinfo ipmi_msghandler',
        'test ! -d /sys/module/ipmi_msghandler' ],
      notify  => Service['ipmi'];

    'load_ipmi_devintf':
      command => 'true',
      # command => 'modprobe ipmi_devintf',
      onlyif  => [ 'modinfo ipmi_devintf',
        'test ! -d /sys/module/ipmi_devintf' ],
      notify  => Service['ipmi'];

    'load_ipmi_si':
      command => 'true',
      # command => 'modprobe ipmi_si',
      onlyif  => [ 'modinfo ipmi_si',
        'test ! -d /sys/module/ipmi_si' ],
      notify  => Service['ipmi'];
  }
}
