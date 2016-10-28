class apache::params {
if ($::fqdn) {
	$servername = $::fqdn
} else {
	$servername = $::hostname
}

$document_root = "/var/www/websites"

$log_dir       = "/var/log/apache"

case $::osfamily {
	'RedHat': {
		$package_name = "httpd"
		$service_name = "httpd"
		$conf_dir     = "/etc/httpd/conf"
		$vhost_dir     = "/etc/httpd/conf.d"
		}
	'Debian': {
		$package_name = "apache2"
                $service_name = "apache2"
                $conf_dir     = "/etc/apache2"
                $vhost_dir    = "/etc/apache2/sites-enabled"
		}

}
}
