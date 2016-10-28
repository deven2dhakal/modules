$topscope = "Thisis from our site.pp file"
node 'default' {

}





node "puppet.master" {
	$nodescope = "defined within our node"
	include localusers
	include localusers::groups::wheel	
	include base
	include base::ssh
	include base::variables
	include localusers::groups::finance
	notify { 'This is a test notify': }



}
