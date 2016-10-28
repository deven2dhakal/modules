Facter.add("primary_interface") do
  confine :kernel => 'Linux'

  setcode do
    ifs = Dir.new("/sys/class/net").each.to_a - \
      Dir.new("/sys/devices/virtual/net").each.to_a

      # filter out ones with no link
      ifs.reject! do |i|
        begin
          File.read("/sys/class/net/#{i}/carrier") != "1\n"
        rescue Errno::EINVAL
          true
        end
      end

    ifs.sort[0]
  end
end
