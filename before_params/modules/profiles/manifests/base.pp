class profiles::base {
  include base
  include base::params
  include base::ssh
  include base::variables
  include localusers::groups::finance
  include localusers::groups::wheel
  include ntp
  class {'ntp': 
     package => 'ntp',
  }
}

