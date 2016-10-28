# os_install_date.rb

Facter.add('os_install_date') do
	setcode do
		# Red Hat based OS
		if File.exists?('/root/anaconda-ks.cfg')
			File.mtime('/root/anaconda-ks.cfg').strftime('%Y/%m/%d-%H:%M:%S')
		end
	end
end
