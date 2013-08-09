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

package Modules::MapExample;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use parent 'Modules::App_Super';
use Log::Log4perl;
use Carp;
use Math::Round 'nlowmult';
use HTML::Template::HashWrapper;
use CGI::Application::Plugin::AutoRunmode;;

use JSON;

sub setup {
	my $self=shift;
	my $logger = Log::Log4perl->get_logger();
	$logger->info("Logger initialized in Modules::MapExample");
}

=head2 MapExample

Run mode for the map_example page 

=cut

sub map_example : StartRunmode {
	my $self = shift;
	my $timeStamp = localtime(time);
	my $template = $self->load_tmpl( 'map_example.tmpl' , die_on_bad_params=>0 );
	return $template->output();
}

1;