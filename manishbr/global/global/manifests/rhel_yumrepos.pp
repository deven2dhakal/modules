# modules/global/manifests/rhel_yumrepos.pp

# Various global config files for Linux hosts
class global::rhel_yumrepos {
  if $::patch_version == '20150701' and $::lsbmajdistrelease == '5' {
    $myBaseUrl = "http://${::yum_filer}/repos/${::patch_version}/OS/RedHat/\$releasever/\$basearch"
  } elsif $::patch_version == '20160101' {
    $myBaseUrl = "http://${::yum_filer}/repos/${::patch_version}/OS/RedHat/\$releasever/\$basearch"
  } else {
    $myBaseUrl = "http://${::yum_filer}/repos/${::patch_version}/OS/RedHat/\$releasever"
  }

  yumrepo {
    # I don't know what to call this since it's more the installer but meh.
    'base-os':
      descr     => 'RedHat-\$releasever - Base',
      baseurl   => $myBaseUrl,
      enabled   => 1,
      gpgkey    => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release',
      exclude   => 'gluster*',
      # assumeyes => 1,
      gpgcheck  => 1;
  }
}
