require 'facter'
Facter.add(:dotomi_user) do
  setcode do
    username = "dotomi"
    Facter::Util::Resolution.exec("/usr/bin/id -u #{username} 2>/dev/null")
  end
end
