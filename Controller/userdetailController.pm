=encoding utf8

=head1 caution

    This perldoc can see in the "perldoc -t " command.

=head1 名前

userdetailController - ユーザ詳細操作用コントローラ

=head1 概要
    
    ユーザの詳細データ変更を行う。
    当機能は、権限がユーザ以上の人のみ利用可能とする。

=head1 使用方法

    use Controller::userdetailController;
    $obj = new Controller::userdetailController(
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

package Controller::userdetailController;

use base qw( Controller::AppController );
use Session;
use Mailfull::Core;
use Mailfull::Common::Config;

sub new {
    my $class = shift;
    my $self = Controller::AppController->new(@_);
    $self->{allow_role} = 1;
    # パラメータとしてdomainが渡されたらセッションに入れてその後その値を使う
    if ($self->params->param('domain')) {
    	$self->{session}->set_session('domain', $self->params->param('domain'));
    }
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
	my $user = $self->{session}->get_session_data('user');
	$self->template->param(DOMAIN => $domain);
	$self->template->param(USER => $user);
	$self->render();
}

sub change {
	my $self = shift;
	$self->template_file('get');
	my $domain = $self->{session}->get_session_data('domain');
	my $user = $self->{session}->get_session_data('user');
	
	my $message = "";
	if (!$self->params->param('password')) {
		$self->set_message($self->get_message($main::ERROR_CD_EMPTY), 'danger');
	} else {
		my $c = Mailfull::Core->user_changepasswd($domain, $self->params->param('user'), $self->params->param('password'));
		if ($c->{retval} != 1) {
			$self->set_message($self->get_message($c->{retval}), 'danger');
		} else {
			Mailfull::Core->commit();
			$self->set_message($self->get_message($c->{retval}), 'success');
		}
	}
	$self->get();
}

sub forward {
	my $self = shift;
	my $domain = $self->{session}->get_session_data('domain');
	my $user = $self->{session}->get_session_data('user');
	
	my $cfg = Mailfull::Common::Config->load;
	my $home_dir = "$cfg->{dir_data}/$domain/$user";
	
	open (FH, "$home_dir/.forward");
	my @line = <FH>;
	close FH;
	
	my $mailing_list = 0;
	my @alias_address;
	if ($line[0] =~ /\#mailing_list/) {
		$mailing_list = 1;
		foreach my $address (@line) {
			if ($address =~ /\@/) {
				push(@alias_address, $address);
			}
		}
	}
	my @ret_line;
	my @ret_alias_address;
	push(@ret_line, {'line' => $_}) foreach (@line);
	push(@ret_alias_address, {'line' => $_}) foreach (@alias_address);

	$self->template->param(DOMAIN => $domain);
	$self->template->param(USER => $user);
	$self->template->param(MAILING_LIST => $mailing_list);
	$self->template->param(LINE => \@ret_line);
	$self->template->param(ALIAS_ADDRESS => \@ret_alias_address);
	$self->render();
}

sub forward_change {
	my $self = shift;
	$self->template_file('forward');
	my $domain = $self->{session}->get_session_data('domain');
	my $user = $self->{session}->get_session_data('user');
	
	my $cfg = Mailfull::Common::Config->load;
	my $home_dir = "$cfg->{dir_data}/$domain/$user";

	open (FH, ">$home_dir/.forward");
	# メーリングリスト設定
	if ($self->params->param('target') == 1) {
		my $mailing_list = $self->params->param('mailing_list');
		my $ailias_mail = $self->params->param('ailias_mail');
		my $result = "\#mailing_list\n";
		$result .= "$home_dir/Maildir/\n";
		if ($mailing_list) {
			foreach my $a(split(/\n/, $ailias_mail)) {
				$a = $self->trim($a);
				if ($a =~ /\@$domain$/) {
					$result .= "$a\n";
				}
			}
		}
		print FH $result;
	# .forward設定
	} else {
		my $forward_edit = $self->params->param('forward_edit');
		print FH $forward_edit;
		
	}
	close FH;
	Mailfull::Core->commit();
	$self->set_message($self->get_message(1), 'success');
	$self->forward();

}
1; 
