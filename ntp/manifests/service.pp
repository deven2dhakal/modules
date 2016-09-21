class ntp::service {
        service { 'ntp_service':
	    name      => $ntp::params::service_name,
	    ensure    => running,
	    enable    => true,
	    subscribe => File['/etc/ntp.conf']
	 

    }


}
