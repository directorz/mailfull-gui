=encoding utf8

=head1 caution

    This perldoc can see in the "perldoc -t " command.

=head1 名前

testController - テスト用コントローラ

=head1 概要
    
    動作テストするためのコントローラ。

=head1 使用方法

    use Controller::testController;
    $obj = new Controller::testController();
    $obj->list();
    exit;
    
=head2 例の一覧

=over 4

=item * これは正丸リストです。

=item * ここに別口があります。

=back

=head1 著作権

Copyright 2014 Unago tentatsu.

This software is released under the MIT License

=cut

package Controller::testController;

use base qw( Controller::AppController );
use Mailfull::Core;
use Data::Dumper;
sub new {
    my $class = shift;
    my $self = Controller::AppController->new;
    return bless $self, $class;
}

sub domains {
	my $self = shift;
	my $c = Mailfull::Core->domains_get;
	
	my @ret;
	push(@ret, {'domain' => ${$c->{ref_domains}}[$_], 'number' => $_}) foreach (0..$#{$c->{ref_domains}});
	$self->template->param(RESULT => \@ret);
	$self->render();
}


sub users {
	my $self = shift;
	my $c = Mailfull::Core->users_get('mail.tentatsu.info');
	        my @ret;
        push(@ret, {'domain' => ${$c->{ref_users}}[$_], 'number' => $_}) foreach (0..$#{$c->{ref_users}});
        $self->template->param(RESULT => \@ret);
        $self->render();
}

1; 
