# Class: localusers
#
# This module manages localusers
#
# Parameters: none
#
# Actions:
#
# Requires: see Modulefile
#
# Sample Usage:
# managehome groupe makes home directory of the user if there is not any
class localusers {
    user {'deven':
      ensure       => present,
      shell        => '/bin/bash',
      home         => '/home/admin',
      gid          => 'wheel',
      managehome   => true,
      password     => '$1$ku4OD5sE$pesTIAigs2XgprG90V2qw/',
      
  }
user {'jeff':
    ensure     => present,
    shell      => '/bin/bash',
    home       => '/home/jeff',
    groups     => ['wheel', 'finance'],
    managehome => true,
       
    
    }
}
