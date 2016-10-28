# Ntpd config. Basic stuff, config file, service, package
#
class ntp::ntpd {

$location = $::ntp::location
$fs = ['AMS5', 'DC6', 'SH5', 'SJ2', 'WL']
$ops = ['AMS', 'IAD', 'ORD', 'SJC']

$foreman_prefer_ntp1 = $::ntp_server1

$fs_ntp_servers = [
       'fs1.ams5.cnvr.net',
       'fs2.ams5.cnvr.net',
       'fs1.dc6.vclk.net',
       'fs2.dc6.vclk.net',
       'fs1.sh5.vclk.net',
       'fs2.sh5.vclk.net',
       'fs1.sj2.vclk.net',
       'fs2.sj2.vclk.net',
       'fs1.wl.vclk.net',
       'fs2.wl.vclk.net',
]
 
$ops_ntp_servers = [
       'dtiad00ops01p.dc.dotomi.net',
       'dtiad00ops02p.dc.dotomi.net',
       'dtord00ops01p.dc.dotomi.net',
       'dtord00ops02p.dc.dotomi.net',
       'dtord00ops88d.vm.dotomi.net',
       'dtsjc00ops01p.dc.dotomi.net',
       'dtsjc00ops02p.dc.dotomi.net',
       'dtams00ops01p.dc.dotomi.net',
       'dtams00ops02p.dc.dotomi.net',
]

notify {"Preferred Foreman NTP Servers for this Datacenter would be : $foreman_prefer_ntp1": }

  package { 'ntp':
    ensure =>  present,
  }

  file { '/etc/ntp.conf':
    owner   => 'root',
    group   => 'ntp',
    mode    => '0640',
    content => template('ntp/ntp.conf.erb'), 
    require => Package['ntp'],
  }

  service { 'ntpd':
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/ntp.conf'],
  }
}
