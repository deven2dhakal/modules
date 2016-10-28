require 'facter'
Facter.add(:foreman_organization) do
    setcode do
      'ESG'
    end
end
