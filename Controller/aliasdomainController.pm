=encoding utf8

=head1 caution

    This perldoc can see in the "perldoc -t " command.

=head1 名前

aliasdomainController - エイリアスドメイン操作用コントローラ

=head1 概要
    
    エイリアスドメインの閲覧、登録、削除を行う。
    当機能は、権限がポストマスター以上の人のみ利用可能とする。

=head1 使用方法

    use Controller::aliasdomainController;
    $obj = new Controller::aliasdomainController(
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

package Controller::aliasdomainController;

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
	my $domain = $self->{session}->get_session_data('domain');
	if (!$domain) {
		$self->show404();
	} else {
		my $c = Mailfull::Core->aliasdomains_get($domain);
		if ($c->{retval} == 1) {
			push(@ret, {'aliasdomain' => ${$c->{ref_aliasdomains}}[$_], 'number' => $_+1}) foreach (0..$#{$c->{ref_aliasdomains}});
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
	if (!$domain || !$self->params->param('aliasdomain')) {
		$self->set_message($self->get_message($main::ERROR_CD_EMPTY), 'danger');
	} else {
		my $c = Mailfull::Core->aliasdomain_add($self->params->param('aliasdomain'), $domain);
		if ($c->{retval} != 1) {
			$self->set_message($self->get_message($c->{retval}), 'danger');
		} else {
			Mailfull::Core->commit();
			$self->set_message($self->get_message($c->{retval}), 'success');
		}
	}
	$self->location('/aliasdomain/get');
}

sub del {
	my $self = shift;
	$self->template_file('get');
	
	if (!$self->params->param('aliasdomain')) {
		$self->set_message($self->get_message($main::ERROR_CD_EMPTY), 'danger');
	} else {
		my $c = Mailfull::Core->aliasdomain_del($self->params->param('aliasdomain'));
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
