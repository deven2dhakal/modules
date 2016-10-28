#/etc/puppet/modules/global/manifests/mk12cdhdisks.pp
class global::mk12cdhdisks {
  exec { 'mk12cdhdisks':
    command => '/root/bin/mk12CDHdisks.sh',
    refreshonly => true,
    path    => "/usr/local/bin/:/bin/:/usr/sbin:/usr/bin/",
  }
}
