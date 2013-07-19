#!/usr/bin/env perl

=pod

=head1 NAME

Modules::Statistics

=head1 DESCRIPTION

=head1 ACKNOWLEDGMENTS

Thank you to Dr. Chad Laing and Dr. Michael Whiteside, for all their assistance on this project

=head1 COPYRIGHT

This work is released under the GNU General Public License v3  http://www.gnu.org/licenses/gpl.htm

=head1 AVAILABILITY

The most recent version of the code may be found at:

=head1 AUTHOR

Akiff Manji (akiff.manji@gmail.com)

=head1 Methods

=cut

package Modules::Statistics;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use parent 'Modules::App_Super';
use Log::Log4perl;
use Carp;

use JSON;

sub setup {
	my $self=shift;
	my $logger = Log::Log4perl->get_logger();
	$logger->info("Logger initialized in Modules::VirulenceFactors");
	$self->start_mode('default');
	$self->run_modes(
		'default'=>'default',
		'stats'=>'Statistics',
		'ajax_test'=>'ajaxTest'
		);
}

=head2 default

Default start mode. Must be decalared or CGI:Application will die. 

=cut

sub default {
	my $self = shift;
	my $template = $self->load_tmpl ( 'hello.tmpl' , die_on_bad_params=>0 );
	return $template->output();
}

=head2 Statistics

Run mode for the statistics page 

=cut

sub Statistics {
	my $self = shift;
	my $template = $self->load_tmpl( 'statistics.tmpl' , die_on_bad_params=>0 );
	return $template->output();
}

sub ajaxTest {
	my $self = shift;
	my $q = $self->query();
	my $name = $q->param('name'); 
	my $game = $q->param('game');

	#my $coder = JSON::XS->new->utf8;
 	#my $perl_scalar = $coder->decode($input);

	my $rtnStr = "Your name is $name, your age is $game";

	#my $rtnStr = "This doesnt work yet";

	return $rtnStr;
}

1;