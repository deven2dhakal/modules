require 'resolv'
 
module Puppet::Parser::Functions
    newfunction(:getname, :type => :rvalue) do |args|
        result = []
        result = Resolv.new.getname(args[0])
        return result
    end
end
