=encoding utf8

=head1 caution

    This perldoc can see in the "perldoc -t " command.

=head1 名前

aliasController - エイリアス操作用コントローラ

=head1 概要
    
    エイリアスの閲覧、登録、削除を行う。
    当機能は、権限がユーザ以上の人のみ利用可能とする。

=head1 使用方法

    use Controller::aliasController;
    $obj = new Controller::aliasController(
        template_dir => $controller, 
        template_file => $method 
    );
    $obj->get();
    exit;
    

=head1 著作権

Copyright 2014 Unago tentatsu.

This software is released under the MIT License

=cut

package Controller::aliasController;

use base qw( Controller::AppController );
use Session;
use Mailfull::Core;

our $role = 2;
sub new {
    my $class = shift;
    my $self = Controller::AppController->new(@_);
    # パラメータとしてuserが渡されたらセッションに入れてその後その値を使う
    if ($self->params->param('user')) {
    	$self->{session}->set_session('user', $self->params->param('user'));
    }
    return bless $self, $class;
}

sub index {
	$self->template_file('get');
	$self->get();
}

sub get {
	my $self = shift;
	my $domain = $self->{session}->get_session_data('domain');
	if (!$domain) {
		$self->show404();
	} else {
		my $c = Mailfull::Core->aliasnames_get($domain);
#			print "Content-Type: text/html\n\n", "404!!";
#			print Dumper $c;
		if ($c->{retval} == 1) {
			push(@ret, {'alias' => ${$c->{ref_aliasnames}}[$_], 'number' => $_+1}) foreach (0..$#{$c->{ref_aliasnames}});
			$self->template->param(DOMAIN => $domain);
			$self->template->param(RESULT => \@ret);
			$self->render();
		} else {
			$self->show404();
		}
	}
}

sub add {
	my $self = shift;
	$self->template_file('get');
	my $domain = $self->{session}->get_session_data('domain');
	
	my $message = "";
	if (!$domain || !$self->params->param('alias')) {
		$self->set_message($self->get_message($main::ERROR_CD_EMPTY), 'danger');
	} else {
		my @dummy = [];
		my $c = Mailfull::Core->alias_add($domain, $self->params->param('alias'), \@dummy);
		if ($c->{retval} != 1) {
			$self->set_message($self->get_message($c->{retval}), 'danger');
		} else {
			$ret = Mailfull::Core->commit();
			$self->set_message($self->get_message($c->{retval}), 'success');
		}
	}
	$self->get();
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


1; 
