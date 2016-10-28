require 'facter'

has_cnvr_principal = "false"
if File.exist?("/usr/bin/klist")
  result = %x{/usr/bin/klist -k /etc/krb5.keytab}
else
  result = "\n\n\n\n"
end

Facter.add('has_cnvr_principal') do
  setcode do
    result.each_line do |line|
      principal = $1 if line =~ /^\s+\d\s+(\s?host\/.*@CNVR.NET)$/
      has_cnvr_principal = "true" if principal
    end
    has_cnvr_principal
  end
end

