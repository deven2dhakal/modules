Facter.add(:odie_serverid) do
        setcode do
                Facter::Util::Resolution.exec("/usr/bin/timeout 3s /home/dotomi/odiereader.py")
        end
end
