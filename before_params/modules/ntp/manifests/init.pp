class ntp {
    package { 'ntp' :
       ensure     => present,

}
        include ntp::params
	include ntp::file
	include ntp::service

}
