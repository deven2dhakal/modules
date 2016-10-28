# provisioning_verison.rb

Facter.add('provisioning_version') do
	setcode do
		if File.exists?('/root/provisioning.ver')
			l = IO.readlines('/root/provisioning.ver')
			l[0].chomp
		elsif File.exists?('/root/provisioningV2') or File.exists?('/root/dtpversion2')
			"2"
		else
			"1"
		end
	end
end
