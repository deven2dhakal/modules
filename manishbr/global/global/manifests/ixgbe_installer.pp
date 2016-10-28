define ixgbe_package($kernel_rel,$set_ixgbe_rpm_ver) {
  if $::kernelrelease ==  $kernel_rel {
    package { "${name}":
        require => [Yumrepo['dotomi-syseng'],Exec['check_ixgbe_version']],
        ensure  => ["${set_ixgbe_rpm_ver}",'installed'],
        notify  => Exec['remove_old_ixgbe'],
    }
    exec {
      'check_ixgbe_version':
        command => '/sbin/modinfo ixgbe; touch /tmp/.ixgbe-3.19.1-k',
        onlyif  => "/sbin/modinfo ixgbe | /bin/grep -q  3.19.1-k";

      'remove_old_ixgbe':
        command => "/sbin/modprobe -r ixgbe; rm -f /tmp/.ixgbe-3.19.1-k; touch /tmp/.ixgbe-${set_ixgbe_rpm_ver}-done",
        onlyif  => 'test -f /tmp/.ixgbe-3.19.1-k';

      '/sbin/depmod -a':
        onlyif      => "test -f /tmp/.ixgbe-${set_ixgbe_rpm_ver}-done",
        require     => Exec['remove_old_ixgbe'];

      'initialize_ixgbe':
        command    => "/sbin/modprobe ixgbe; rm -f /tmp/.ixgbe-${set_ixgbe_rpm_ver}-done",
        onlyif     => "test -f /tmp/.ixgbe-${set_ixgbe_rpm_ver}-done",
        require    => Exec['/sbin/depmod -a'];
    }
  } else {
    notify {"Not installing your kernel release is $::kernelrelease":}
  }
}
define ixgbe_device_name {
  include stdlib
  if $name == 'ixgbe' {
    if !empty($::primary_interface){
      #ixgbe_package {$name: kernel_rel => '2.6.32-504.8.1.el6.x86_64'}
      ixgbe_package { $name: kernel_rel => $::kernelrelease ? { '2.6.32-504.8.1.el6.x86_64' => '2.6.32-504.8.1.el6.x86_64', '2.6.32-504.el6.x86_64' => '2.6.32-504.el6.x86_64' },
        set_ixgbe_rpm_ver => $::kernelrelease ? { '2.6.32-504.8.1.el6.x86_64' => '3.23.2.1-1', '2.6.32-504.el6.x86_64' => '4.0.3-1', }, }
    }
  }
  else {
      notice('not the right driver and vendor')
  }
}

define global::ixgbe_installer {
  if $::hostname =~ /^dtiad08lvs0[1-6]p$/ or $::dcnode =~ /^(iad00|sjc0[56])/ {
  #if $::hostname =~ /^dtiad0[7-8](nsy|dma|rtb)\d+p$/ or $::hostname =~ /^dtiad00cls\d+p$/{
  #if $::hostname  =~ /^dtiad0[1-6]mem1[3-8]p/ { # or ($::dcnode == 'iad07') {
    $types = ['vendor', 'driver', 'device']
    $devices = split(inline_template("<%= name %>"),',')
    $ifs_drv = chomp(inline_template("<% devices.each do |controller| -%> <%types.each do |type| -%><%=scope.lookupvar(controller+'_'+type) %>,<% end -%><% end -%>"))
    $results = unique(flatten(split(inline_template("<%= ifs_drv %>"),',')))

    ixgbe_device_name {$results:}
  }
}
