# /etc/puppet/modules/global/manifests/centos_yumrepos.pp

# Various global config files for Linux hosts
class global::centos_yumrepos {
  if $::provisioning_version >= 5 {
    $myPatchVersion = $::patch_version
  } else {
    $myPatchVersion = 20150630
  }

  /* Setting defaults on user-defined things */
  yumrepo {
    'base-os':
      descr     => 'CentOS-$releasever - Base',
      baseurl   => "http://${::yum_filer}/repos/${myPatchVersion}/OS/CentOS/\$releasever/os/\$basearch",
      enabled   => 1,
      gpgkey    => "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-${::lsbmajdistrelease}",
      exclude   => 'gluster*',
      # assumeyes => 1,
      gpgcheck  => 1;
    'base-updates':
      descr     => 'CentOS-$releasever - Updates',
      baseurl   => "http://${::yum_filer}/repos/${myPatchVersion}/OS/CentOS/\$releasever/updates/\$basearch",
      enabled   => 1,
      gpgkey    => "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-${::lsbmajdistrelease}",
      exclude   => 'gluster*',
      # assumeyes => 1,
      gpgcheck  => 1;
  }

  if $::lsbmajdistrelease == 7 {
    yumrepo {
      'base-extras':
        descr     => 'CentOS-$releasever - Extras',
        baseurl   => "http://${::yum_filer}/repos/${myPatchVersion}/OS/CentOS/\$releasever/extras/\$basearch",
        enabled   => 1,
        exclude   => 'gluster*',
        # assumeyes => 1,
        gpgcheck  => 1;
    }
  }
}
