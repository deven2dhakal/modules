Facter.add(:qa_lane) do
    confine :kernel => 'Linux'
    setcode do
	Facter::Util::Resolution.exec('hostname -s | grep -Po "\d+\w{3}\d+" | cut -c 3-')
	end
end

