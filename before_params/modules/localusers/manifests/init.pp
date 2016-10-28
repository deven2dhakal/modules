class localusers {
  user { 'ram':
  ensure         => present,
  shell          => '/bin/bash',
  home           => '/home/ram',
  gid            => 'wheel',
  password       => '$1$wxZ5$vWmT28yFymT/4XBYq1tz51',
  managehome     => true,
	}

	user {'jeff':
		ensure =>   present,
		shell      => '/bin/bash',
		home       => '/home/jeff',
		groups      => ['wheel', 'finance',],
		managehome => true,
	}



}

