package Controller::AppController;
use Encode;
use Session;
use Data::Dumper;

sub new {
	my $class = shift;
	my $self = {@_};
	
	$self->{params} = CGI->new();
	$self->{session} = Session->new();
	$self->{layout} = 'default';
	$self->{message} = $main::MESSAGE;
	$self->{info_message} = "";
	$self->{info_context} = "";
	return bless $self, $class;
}

# 権限チェック。自分の権限がコントローラの必要権限より小さい場合は自分が行くべきページTOPへ強制送還する。
sub before_role_check {
	my $self = shift;
	my $role = shift if (@_);
	if ($role < $self->{allow_role}) {
		my $route = $main::ROLE_ROUTES;
		if ($$route{$role}) {
			print "Location:http://". $ENV{'HTTP_HOST'}. $$route{$role}."\n"; 
		} else {
			print "Location:http://". $ENV{'HTTP_HOST'}. '/login/'."\n"; 
		}
	}
}

sub get_message {
	my $self = shift;
	my $message_number = shift;
	
	my $message_master = $self->{message};
	if (!exists($$message_master{$message_number})) {
		$message_number = 999;
	}
	return decode('utf-8', $$message_master{$message_number});

}

sub params {
	return shift->{params};
}

sub template_dir {
	my $self = shift;
	$self->{template_dir} = shift if(@_);
	return $self->{template_dir};
}

sub template_file {
	my $self = shift;
	my $ret= $self->{template_file};
	$self->{template_file} = shift if(@_);
	return $ret;
}

sub template {
	my $self = shift;
	if (!$self->{template}) { 
		$self->{template} = HTML::Template->new(
			filename => 'template/'.$self->{template_dir} .'/' . $self->{template_file}. '.tmpl',
			die_on_bad_params => 0,
			binmode => ':utf8'
		);
		if ($self->{role}) {
			$self->{template}->param(USER_ROLE => $self->{role});
			if ($self->{role} eq $main::MASTER_ROLE) {
				$self->{template}->param(MASTER_ROLE_ME => 1);
				$self->{template}->param(POSTMASTER_ROLE_ME => 1);
				$self->{template}->param(USER_ROLE_ME => 1);
			} elsif ($self->{role} eq $main::POSTMASTER_ROLE) {
				$self->{template}->param(MASTER_ROLE_ME => 0);
				$self->{template}->param(POSTMASTER_ROLE_ME => 1);
				$self->{template}->param(USER_ROLE_ME => 1);
			} elsif ($self->{role} eq $main::USER_ROLE) {
				$self->{template}->param(MASTER_ROLE_ME => 0);
				$self->{template}->param(POSTMASTER_ROLE_ME => 0);
				$self->{template}->param(USER_ROLE_ME => 1);
			}
		} else {
			$self->{template}->param(MASTER_ROLE_ME => 0);
			$self->{template}->param(POSTMASTER_ROLE_ME => 0);
			$self->{template}->param(USER_ROLE => 0);
		}
		
	}
	return $self->{template};
}

sub layout {
	my $self = shift;
	$self->{layout} = shift if(@_);
	return $self->{layout};
}

sub set_message {
	my $self = shift;
	$self->{info_message} = shift if(@_);
	$self->{info_context} = shift if(@_);
}
sub render {
	my $self = shift;
	my %option = {@_} if(@_);
	$layout_template = HTML::Template->new(
			filename => 'template/Layout/'. $self->layout. '.tmpl',
			binmode => ':utf8'
	);
	$layout_template->param(MAIN_CONTENTS => $self->template->output);
	$layout_template->param(INFO_MESSAGE => $self->{info_message});
	$layout_template->param(INFO_CONTEXT => $self->{info_context});
	
	if (!exists($option{'noheader'})) {
		print "Content-Type: text/html\n\n";
	}
	print encode('utf-8', $layout_template->output);
}

sub show404 {
	my $self = shift;
	my $message = shift if(@_);
	$message = '該当のページは存在しません。再度TOPページから入りなおして下さい。' unless ($message);
	$layout_template = HTML::Template->new(
			filename => 'template/Layout/'. $self->layout. '.tmpl',
			binmode => ':utf8'
	);
	if (!$self->{template}) { 
		$self->{template} = HTML::Template->new(
			filename => 'template/404.tmpl',
			binmode => ':utf8'
		);
		$self->{template}->param(MESSAGE => decode('utf-8', $message));
	}
	$layout_template->param(MAIN_CONTENTS => $self->template->output);
	print "Content-Type: text/html\n\n";
	print encode('utf-8', $layout_template->output);
}

sub trim {
	my $self = shift;
	my $val = shift;
	$val =~ s/^ *(.*?) *$/$1/;
	$val =~ s/\r//;
	$val =~ s/\n//;
	return $val;
}

sub vd {
	my $self = shift;
	print "Content-Type: text/html\n\n";
	print Dumper @_;
	exit;
}
1;
