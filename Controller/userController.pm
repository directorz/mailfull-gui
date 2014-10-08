=encoding utf8

=head1 caution

    This perldoc can see in the "perldoc -t " command.

=head1 名前

userController - ユーザ操作用コントローラ

=head1 概要
    
    ユーザの閲覧、登録、削除を行う。
    当機能は、権限がポストマスター以上の人のみ利用可能とする。

=head1 使用方法

    use Controller::userController;
    $obj = new Controller::userController(
        template_dir => $controller, 
        template_file => $method, 
        role => $role
    );
    $obj->get();
    exit;
    

=head1 著作権

Copyright 2014 Unago tentatsu.

This software is released under the MIT License

=cut

package Controller::userController;

use base qw( Controller::AppController );
use Session;
use Mailfull::Core;

sub new {
    my $class = shift;
    my $self = Controller::AppController->new(@_);
    $self->{allow_role} = 2;
    # パラメータとしてdomainが渡されたらセッションに入れてその後その値を使う
    if ($self->params->param('domain')) {
    	$self->{session}->set_session('domain', $self->params->param('domain'));
    }
    return bless $self, $class;
}

sub index {
	$self->template_file('get');
	$self->get();
}

sub get {
	my $self = shift;
	my $show_taget = shift if(@_);
	my $domain = $self->{session}->get_session_data('domain');
	if (!$domain) {
		$self->show404();
	} else {
		# ユーザとキャッチオールの取得
		my $c = Mailfull::Core->users_get($domain);
#			print "Content-Type: text/html\n\n", "404!!";
#			print Dumper $c;
		if ($c->{retval} == 1) {
			my $ca = Mailfull::Core->catchall_get($domain);
			my $catchall_user = "";
			if ($ca->{retval} == 1) {
				$catchall_user = $ca->{user_catchall};
			}
			push(@ret, {
				'user' => ${$c->{ref_users}}[$_], 
				'number' => $_+1, 
				'catchall' => ($catchall_user eq ${$c->{ref_users}}[$_]) ? 1 : 0}) foreach (0..$#{$c->{ref_users}});
			$self->template->param(DOMAIN => $domain);
			$self->template->param(RESULT => \@ret);

			# エイリアスユーザと配送先の取得
			my $a = Mailfull::Core->aliasnames_get($domain);
			my $a_users = $a->{ref_aliasnames};
			my @alias_ret;
			my $i = 1;
			foreach my $u (@$a_users) {
				my $a = Mailfull::Core->aliasdests_get($domain, $u);
				my %tmp;
				my @dests;
				$tmp{user} = $u;
				$tmp{number} = $i++;
				push(@dests, {'alias_user' => $u, 'name' => ${$a->{ref_aliasdests}}[$_]}) foreach (0..$#{$a->{ref_aliasdests}});
				$tmp{dests} = \@dests;
				push (@alias_ret, \%tmp);
			}
			$self->template->param(ALIAS_RESULT => \@alias_ret);
			
			my $show_alias = 0;
			my $show_add = 0;
			if (defined $show_taget && $show_taget eq 'alias') {
				$show_alias = 1;
			} elsif (defined $show_taget && $show_taget eq 'add') {
				$show_add = 1;
			}
			$self->template->param(SHOW_ALIAS => $show_alias);
			$self->template->param(SHOW_ADD => $show_add);

			$self->render();
		} else {
			$self->show404();
		}
	}
}

sub alias {
	my $self = shift;
	$self->template_file('get');
	$self->get('alias');
}
sub add {
	my $self = shift;
	$self->template_file('get');
	my $domain = $self->{session}->get_session_data('domain');
	
	my $message = "";
	if (!$domain || !$self->params->param('user') || !$self->params->param('password')) {
		$self->set_message($self->get_message($main::ERROR_CD_EMPTY), 'danger');
	} else {
		my $c = Mailfull::Core->user_add($domain, $self->params->param('user'), $self->params->param('password'));
		if ($c->{retval} != 1) {
			$self->set_message($self->get_message($c->{retval}), 'danger');
		} else {
			Mailfull::Core->commit();
			$self->set_message($self->get_message($c->{retval}), 'success');
		}
	}
	$self->get('add');
}

sub del {
	my $self = shift;
	$self->template_file('get');
	my $domain = $self->{session}->get_session_data('domain');
	
	if (!$domain || !$self->params->param('user')) {
		$self->set_message($self->get_message($main::ERROR_CD_EMPTY), 'danger');
	} else {
		my $c = Mailfull::Core->user_del($domain, $self->params->param('user'));
		if ($c->{retval} != 1) {
			$self->set_message($self->get_message($c->{retval}), 'danger');
		} else {
			Mailfull::Core->commit();
			$self->set_message($self->get_message($c->{retval}), 'success');
		}
	}
	$self->get();
}

sub catchall_set {
	my $self = shift;
	$self->template_file('get');
	my $domain = $self->{session}->get_session_data('domain');
	
	if (!$domain || !$self->params->param('user')) {
		$self->set_message($self->get_message($main::ERROR_CD_EMPTY), 'danger');
	} else {
		my $c = Mailfull::Core->catchall_del($domain);
		# キャッチオール未設定：302で返ってくる
		if ($c->{retval} == 1 || $c->{retval} == 302) {
			my $c = Mailfull::Core->catchall_set($domain, $self->params->param('user'));
			if ($c->{retval} != 1) {
				$self->set_message($self->get_message($c->{retval}), 'danger');
			} else {
				Mailfull::Core->commit();
				$self->set_message($self->get_message($c->{retval}), 'success');
			}
		} else {
			$self->set_message($self->get_message($c->{retval}), 'danger');
		}
	}
	$self->get();

}

sub catchall_del {
	my $self = shift;
	$self->template_file('get');
	my $domain = $self->{session}->get_session_data('domain');
	
	if (!$domain) {
		$self->set_message($self->get_message($main::ERROR_CD_EMPTY), 'danger');
	} else {
		my $c = Mailfull::Core->catchall_del($domain);
		# キャッチオール未設定：302で返ってくる
		if ($c->{retval} == 1 || $c->{retval} == 302) {
			Mailfull::Core->commit();
			$self->set_message($self->get_message($c->{retval}), 'success');
		} else {
			$self->set_message($self->get_message($c->{retval}), 'danger');
		}
	}
	$self->get();
}

sub alias_add {
	my $self = shift;
	$self->template_file('get');
	my $domain = $self->{session}->get_session_data('domain');
	
	my $message = "";
	if (!$domain || !$self->params->param('alias') || !$self->params->param('dest')) {
		$self->set_message($self->get_message($main::ERROR_CD_EMPTY), 'danger');
	} else {
		my @alias_dest = ($self->params->param('dest'). '@'. $domain);
		my $c = Mailfull::Core->alias_add($domain, $self->params->param('alias'), \@alias_dest);
		if ($c->{retval} != 1) {
			$self->set_message($self->get_message($c->{retval}), 'danger');
		} else {
			$ret = Mailfull::Core->commit();
			$self->set_message($self->get_message($c->{retval}), 'success');
		}
	}
	$self->get('alias');
}

sub alias_del {
	my $self = shift;
	$self->template_file('get');
	my $domain = $self->{session}->get_session_data('domain');
	
	my $message = "";
	if (!$domain || !$self->params->param('user') || !$self->params->param('dest')) {
		$self->set_message($self->get_message($main::ERROR_CD_EMPTY), 'danger');
	} else {
		my @alias_dest = ($self->params->param('dest'));
		my $c = Mailfull::Core->alias_del($domain, $self->params->param('user'), \@alias_dest);
		if ($c->{retval} != 1) {
			$self->set_message($self->get_message($c->{retval}), 'danger');
		} else {
			Mailfull::Core->commit();
			$self->set_message($self->get_message($c->{retval}), 'success');
		}
	}
	$self->get('alias');
}

sub alias_full_del {
	my $self = shift;
	$self->template_file('get');
	my $domain = $self->{session}->get_session_data('domain');
	
	if (!$domain || !$self->params->param('user')) {
		$self->set_message($self->get_message($main::ERROR_CD_EMPTY), 'danger');
	} else {
        my @empty = ();
        my $c = Mailfull::Core->alias_set($domain, $self->params->param('user'), \@empty);
        
		if ($c->{retval} == 1) {
			$self->set_message($self->get_message($c->{retval}), 'success');
		} else {
			Mailfull::Core->commit();
			$self->set_message($self->get_message($c->{retval}), 'danger');
		}
	}
	$self->get('alias');
}

sub alias_dest_add {
	my $self = shift;
	$self->template_file('get');
	my $domain = $self->{session}->get_session_data('domain');
	
	my $message = "";
	if (!$domain || !$self->params->param('user') || !$self->params->param('dest')) {
		$self->set_message($self->get_message($main::ERROR_CD_EMPTY), 'danger');
	} else {
		my $dest = $self->params->param('dest');
		if ($dest =~ /@/) {
			@tmp = split('@', $dest);
			$dest = $tmp[0];
		}
		my @alias_dest = ($dest. '@'. $domain);
		my $c = Mailfull::Core->alias_add($domain, $self->params->param('user'), \@alias_dest);
		if ($c->{retval} != 1) {
			$self->set_message($self->get_message($c->{retval}), 'danger');
		} else {
			Mailfull::Core->commit();
			$self->set_message($self->get_message($c->{retval}), 'success');
		}
	}
	$self->get('alias');
}


1; 
