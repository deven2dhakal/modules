require 'facter'

principals_arr = []

if File.exist?("/usr/bin/klist")
    result = %x{/usr/bin/klist -k /etc/krb5.keytab}
else
    result = "\n\n\n\n"
end

Facter.add('krb5_principals') do
  setcode do
    result.each_line do |line|
      principal = $1 if line =~ /^\s+\d\s+(\w+\/.*@.+)$/
      if principal
        principals_arr << principal
      end
    end
    principals_arr
  end
end

