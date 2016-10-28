class base::variables {
	
	$localvar = "local var"
	$topscope = "new top scope value"
	$nodescope = "new node scope variable"
	
	notify { "${::topscope} is your top scope variable": }
	notify { "${nodescope} is your node scope variable": }
	notify { "${localvar} is your local var variable": }
	notify { "${::operatingsystem} is your operating system": }
	}
