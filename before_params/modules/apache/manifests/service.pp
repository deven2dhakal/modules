class apache::service ($service_name = $apache::params::service_name) {
		service { 'apache' :
			name     => $service_name,
			ensure   => running,
			enable   => true,
			require  => Package['apache'],
			}
}
