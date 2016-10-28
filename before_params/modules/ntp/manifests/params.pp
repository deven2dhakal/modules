class ntp::params {



     case $::operatingsystem {

         'ubuntu': { 
		 $template = 'ntp_ubuntu.conf'
		 $service_name = 'ntp' 
		 $default_servers = [ "0.ubuntu.pool.ntp.org",
                                         "1.ubuntu.pool.ntp.org",
                                         "2.ubuntu.pool.ntp.org",
                                         "3.ubuntu.pool.ntp.org",]
		}

         'centos': { 
		$template = 'ntp_centos.conf'
		$service_name = 'ntpd' 
		$default_servers = [ "0.centos.pool.ntp.org iburst",
					 "1.centos.pool.ntp.org iburst",
					 "2.centos.pool.ntp.org iburst",
					 "3.centos.pool.ntp.org iburst",]

		}
         'default': { 
		fail('os $::operatingsystem is not currently supported') 

		}
         }	

}
