Facter.add('is_docker') do
confine :kernel => 'Linux'
    setcode do
        check_cgroup = Pathname.new('/proc/1/cgroup')
        if check_cgroup.readable?
            dock = check_cgroup.readlines.any? {|l| l.include?('docker')}
            dock
        else
            false
        end
    end
end
