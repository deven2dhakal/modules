# Manage local users and passwords (primarily root, maybe others)
#
class global::users {

  $rp = file('/etc/puppet/data/secure/shadow/root-esg')
  $root_password = chomp($rp)

  user { 'root':
    ensure   => present,
    password => $root_password,
  }

}
