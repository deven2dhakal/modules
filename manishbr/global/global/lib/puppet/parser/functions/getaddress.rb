require 'resolv'
 
module Puppet::Parser::Functions
    newfunction(:getaddress, :type => :rvalue) do |args|
        result = []
        result = Resolv.new.getaddress(args[0])
        return result
    end
end
