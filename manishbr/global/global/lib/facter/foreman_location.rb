#!/bin/env ruby
require 'socket'
require 'resolv'
require 'ipaddr'

Facter.add(:foreman_location) do

ip = Resolv::getaddress(Socket.gethostname)

networks = { '10.110.0.0/16' => 'ORD',
             '10.10.0.0/14' => 'STO',
             '10.16.0.0/14' => 'LA',
             '10.20.0.0/14' => 'SH5',
             '10.24.0.0/14' => 'AMS5',
             '10.28.0.0/14' => 'SJ2',
             '10.32.0.0/14' => 'WL',
             '10.36.0.0/14' => 'DC6',
             '10.40.0.0/14' => 'SH1',
             '10.44.0.0/14' => 'STO',
             '192.168.216.0/22' => 'SJ2',
             '192.168.240.0/24' => 'SJ2',
             '172.30.0.0/16' => 'WL',
             '172.31.0.0/16' => 'ORD',
             '10.120.0.0/16' => 'SJC',
             '10.130.0.0/16' => 'IAD',
             '10.31.0.0/16' => 'SJC',
             '10.30.0.0/16' => 'SJC',
             '10.125.0.0/16' => 'SJC',
             '10.26.0.0/16' => 'AMS',
             '0.0.0.0/0'  => "Unknown"}

def net_match (networks_hash, ip)
  matching_networks = Hash.new
  me = IPAddr.new(ip)

  networks_hash.each {|network, datacenter|
    net = IPAddr.new(network)
    if net.include?(me) then
      prefix_length = net.to_i.to_s(2).count("1")
      matching_networks[prefix_length] = datacenter
    end
  }
  return matching_networks[matching_networks.keys.sort.last]
end

  setcode do 
    net_match(networks, ip)
  end
end
