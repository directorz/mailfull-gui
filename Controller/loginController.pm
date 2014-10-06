=encoding utf8

=head1 caution

	This perldoc can see in the "perldoc -t " command.

=head1 名前

loginController - ログインコントローラ

=head1 概要
	
	ログイン画面を表示、ログイン後セッションの発行を行う

=head1 使用方法

	use Controller::loginController;
	$obj = new Controller::loginController();
	$obj->login();
	exit;
	

=back

=head1 著作権

Copyright 2014 Unago tentatsu.

This software is released under the MIT License

=cut

package Controller::loginController;

use base qw( Controller::AppController );
use Mailfull::Core;
use Session;
use Data::Dumper;

use CGI;
use DB_File;
use DBM_Filter;
use Digest::MD5 qw(md5_hex);
use Session;

sub new {
	my $class = shift;
	my $self = Controller::AppController->new(@_);
	return bless $self, $class;
}

sub index {
	my $self = shift;
	my $session_id = undef;
	my $error_message = "";
	my $user = "";
	my $domain = "";
	my $role = 0;
	if ($self->params->param('login_button')) {
		my $user = $self->params->param('user');
		my $pass = $self->params->param('password');
		if (length($user) && length($pass)) {
			# マスターユーザか調べる
			if ($user eq $main::MASTER_USER_ID &&
				$pass eq $main::MASTER_USER_PW
			) {
				$role = $main::MASTER_ROLE;
			} else {
				($user, $domain) = split(/@/, $user, 2);
				if (length($user) && defined($domain) && length($domain)) {
					my $c = Mailfull::Core->user_checkpasswd($domain, $user, $pass);
					if ($$c{retval} == 1) {
						# postmasterか調べる
						if ($user eq 'postmaster') {
							$role = $main::POSTMASTER_ROLE;
						} else {
							$role = $main::USER_ROLE;
						}
					}
				}
			}
		}
		if ($role) {
			$s = new Session();
			$session_id = $s->make_session($role);
			if ($role == $main::POSTMASTER_ROLE || $role == $main::USER_ROLE) {
				$s->set_session('domain', $domain);
			}
			if ($role == $main::USER_ROLE) {
				$s->set_session('user', $user);
			}
			$q = CGI->new;
			my $cookie = $q->cookie(
				-name    => $main::SESSION_ID,
				-value   => $session_id,
				-expires => sprintf( '+%dh', $main::SESSION_FILE_DURATION ),
			);

			#ヘッダ書き出し
			my $route = $main::ROLE_ROUTES;
			print "Location:http://". $ENV{'HTTP_HOST'}. $$route{$role}."\n"; 
			print "Set-Cookie: $cookie;\n"; 
			print "\n"; # 空行 

			exit;
		} else {
			$self->set_message($self->get_message($main::ERROR_CD_NO_LOGIN), 'danger');
			$self->render();
			print $self->params->param('user');
		}
	} else {
		$self->render(noheader => 1);
		print $self->params->param('user');
	}
}

sub logout {
	my $self = shift;
	$self->template_file('index');
	
		my $s = new Session();
	my $session_id = $s->get_session_id();
	my $session_file = $main::SESSION_DIR. "/$session_id";
	if (-e $session_file) {
		unlink $session_file;
	}
	
	$q = CGI->new;
	my $cookie = $q->cookie(
		-name    => $main::SESSION_ID,
		-value   => $session_id,
		-expires => 'Thu, 1-Jan-1970 00:00:00 GMT',
	);
	$self->{role} = undef;
	
	print "Content-Type: text/html\n";
	print "Set-Cookie: $cookie;\n";
	$self->template_file('index');
	$self->render(noheader => 1);
}

sub get_role {
	my $self = shift;
	my $session_id = shift;
	my $session_file = $main::SESSION_DIR. "/$session_id";
	
	#セッションデータファイルを開く (無い時は作成) 
	tie( %sessionvals, 'DB_File', $session_file, O_RDWR , 0600, $DB_HASH )
		or &fatal_error( "Tieing $session_file", $! );
	
	
	return $sessionvals{$main::SESSION_FILE_ROLE} if(exists($sessionvals{$main::SESSION_FILE_ROLE}));
	return undef;
}


#sub get {
#	my $self = shift;
#	my $c = Mailfull::Core->domains_get;
#	
#	my @ret;
#	push(@ret, {'domain' => ${$c->{ref_domains}}[$_], 'number' => $_}) foreach (0..$#{$c->{ref_domains}});
#	$self->template->param(RESULT => \@ret);
#	$self->render();
#}
#
#sub add {
#	my $self = shift;
#	my $message = "";
#	if (!$self->params->param('domain') || !$self->params->param('password')) {
#		$message = $self->get_message($main::ERROR_CD_EMPTY);
#		print $message;exit;
#	}
#	my $c = Mailfull::Core->domain_add($self->params->param('domain'), $self->params->param('password'));
#	print Dumper $self->get_message($$c{retval});exit;
#	$self->template->param(RESULT => \@ret);
#}
#
#sub del {
#	my $self = shift;
##	domain_del
#	if (!$self->params->param('domain')) {
#		$message = $self->get_message($main::ERROR_CD_EMPTY);
#		print $message;exit;
#	}
#	
#	my $c = Mailfull::Core->domain_del($self->params->param('domain'));
#	print Dumper $self->get_message($$c{retval});exit;
#	$self->template->param(RESULT => \@ret);
#	
#}
#
#sub users {
#	my $self = shift;
#	my $c = Mailfull::Core->users_get('mail.tentatsu.info');
#	        my @ret;
#	    push(@ret, {'domain' => ${$c->{ref_users}}[$_], 'number' => $_}) foreach (0..$#{$c->{ref_users}});
#	    $self->template->param(RESULT => \@ret);
#	    $self->render();
#}

1; 
