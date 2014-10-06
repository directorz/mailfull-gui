#!/usr/bin/perl -w 
use strict;
use warnings;
#	use utf8;
use lib qw { lib /home/mailfull/lib };
use Controller::loginController;
use HTML::Template;
use CGI;
use Data::Dumper;
use const;

my $q = CGI->new();
my ($controller, $method) = &get_controller_action;

use Session;
my $s = new Session();


# セッションの取得を行う。なきゃログインへGO！
my $login_obj = Controller::loginController->new(template_dir => 'login', template_file => 'index');
my $session_id = $q->cookie($main::SESSION_ID) || "";
my $role = 0;
if (length($session_id) && $session_id =~ /$main::SESSION_FILE_REG/ && -f $main::SESSION_DIR. "/". $session_id) {
	
	# 自分のロールを取得、なければログインへ
	$role = $login_obj->get_role($session_id);
	if (!$role) {
		$login_obj->index();
	}
	
	if ($controller eq 'index' && $method eq 'index') {
		my $route = $main::ROLE_ROUTES;
		if ($$route{$role}) {
			print "Location:http://". $ENV{'HTTP_HOST'}. $$route{$role}."\n\n"; 
		} else {
			print "Location:http://". $ENV{'HTTP_HOST'}. '/login/'."\n\n"; 
		}
		exit;
	}
	
	my $obj_name = 'Controller::'.$controller. 'Controller';
	
	# コントローラの存在確認。無ければ404
	unless (eval "use $obj_name ; 1") {
		# 404
		$login_obj->show404();
		exit;
	}
	my $obj = $obj_name->new(template_dir => $controller, template_file => $method, role => $role);
	
	$obj->before_role_check($role);
	# methodは取得できなければindexを表示
	unless ($obj->can($method)) {
		$method = 'index';
	}
	$obj->$method(); 
	
} else {
	# ログイン画面表示
	$login_obj->index();
	
}

# コントローラ、アクションの取得。postで処理された場合にGETのデータをCGIでは取得できないのでQUERY_STRINGで取得する。
sub get_controller_action {
	my @array = split(/&/,$ENV{'QUERY_STRING'});
	my $controller = "index";
	my $action = "index";
	foreach my $set (@array) {
		my ($key,$value) = split(/=/, $set);
		$controller = $value if ($key eq 'controller');
		$action = $value if ($key eq 'action');
	}
	return $controller, $action;
}

1;
