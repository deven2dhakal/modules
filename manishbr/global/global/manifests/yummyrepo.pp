# modules/global/manifests/yummyrepo.pp

define global::yummyrepo () {
  include stdlib

  $yumYaml = loadyaml('/etc/puppet/data/shared/global/yumrepos.yaml')

  # Here we interpolate variables via an erb which is safe
  $baseurl = inline_template(inline_template("<%= @yumYaml[@title]['baseurl'] %>"))

  if $yumYaml[$title]['gpgkey'] {
    $gpgkey = inline_template(inline_template("<%= @yumYaml[@title]['gpgkey'] %>"))
  }

  if $yumYaml[$title]['gpgkey'] {
    $myhash = {
      'baseurl' => $baseurl,
      'gpgkey'  => $gpgkey,
    }
  } else {
    $myhash = {
      'baseurl' => $baseurl,
    }
  }

  # yamlback.erb returns a yaml with certain variables interpolated
  $yumHash = parseyaml(template('global/yamlback.erb'))

  unless defined(Yumrepo[$title]) {
    create_resources(yumrepo, $yumHash)
  }
}
