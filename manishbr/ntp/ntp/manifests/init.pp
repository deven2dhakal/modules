# First pass
# note: foreman sometimes changes the way you need to do things. Since the
# default gateway parameter is tied to the host's subnet in foreman, it isn't
# available to puppet directly. This requires us to add a parameter that will
# be overridden by puppet to '<%= @host.subnet.gateway %>'. I've set the
# default value in the class to something that should make this obvious.
#
# 8/27/15: We're using chrony exclusively on RHEL7 and above, and ntp on 
# everything else. No need to pass a package

class ntp (
$ntp_application = 'ntpd',
$_ntpServers = [ '0.north-america.pool.ntp.org', '1.north-america.pool.ntp.org', '2.north-america.pool.ntp.org', '3.north-america.pool.ntp.org' ],
$ntp_server = $::default_gateway,
$location = $::foreman_location,
) {
  # this is a little dumb. I wanted to do:
  # include ntp::${ntp_application}
  # here, but that's not syntactically valid. So...

  require syseng

  if has_interface_with('docker0') {
    $real_ntp_server = get_v4_network($::fqdn)['gateway']
  } else {
    $real_ntp_server = $::ntp::ntp_server
  }

  case $ntp_application {
    'ntpd':   { include ntp::ntpd }
    'chrony': { include ntp::chrony }
    default:  { include ntp::ntpd }
  } 
  
    
}
