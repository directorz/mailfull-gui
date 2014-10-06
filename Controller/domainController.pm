=encoding utf8

=head1 caution

    This perldoc can see in the "perldoc -t " command.

=head1 名前

domainController - ドメイン操作用コントローラ

=head1 概要
    
    ドメインの閲覧、登録、削除を行う。
    当機能は、権限がマスター以上の人のみ利用可能とする。

=head1 使用方法

    use Controller::domainController;
    $obj = new Controller::domainController(
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

package Controller::domainController;

use base qw( Controller::AppController );
use Mailfull::Core;

sub new {
    my $class = shift;
    my $self = Controller::AppController->new(@_);
    $self->{allow_role} = 99;
    return bless $self, $class;
}

sub index {
	$self->template_file('get');
	$self->get();
}

sub get {
	my $self = shift;
	my $c = Mailfull::Core->domains_get;
	
	my @ret;
	push(@ret, {'domain' => ${$c->{ref_domains}}[$_], 'number' => $_+1}) foreach (0..$#{$c->{ref_domains}});
	$self->template->param(RESULT => \@ret);
	$self->render();
}

sub add {
	my $self = shift;
	$self->template_file('get');
	
	my $message = "";
	if (!$self->params->param('domain') || !$self->params->param('password')) {
		$self->set_message($self->get_message($main::ERROR_CD_EMPTY), 'danger');
	} else {
		my $c = Mailfull::Core->domain_add($self->params->param('domain'), $self->params->param('password'));
		if ($c->{retval} != 1) {
			$self->set_message($self->get_message($c->{retval}), 'danger');
		} else {
			Mailfull::Core->commit();
			$self->set_message($self->get_message($c->{retval}), 'success');
		}
	}
	$self->get();
}

sub del {
	my $self = shift;
	$self->template_file('get');
	
	if (!$self->params->param('domain')) {
		$self->set_message($self->get_message($main::ERROR_CD_EMPTY), 'danger');
	} else {
		my $c = Mailfull::Core->domain_del($self->params->param('domain'));
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
