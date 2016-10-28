define global::fusion_io_mnt($device){

  file {
    $name:
      ensure  => 'directory',
  }
  #Mount the Fusion-IO Card
  mount {
    $name:
      atboot  => yes,
      device  => "/dev/${device}",
      fstype  => "ext4",
      ensure  => 'mounted',
      options => "defaults,noauto,data=writeback,discard,noatime,nodiratime",
      pass    => '0',
      dump    => '0',
      require => File["${name}"],
  }
}
