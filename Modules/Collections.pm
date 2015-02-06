#!/usr/bin/env perl

=pod

=head1 NAME

Modules::Collection

=head1 SNYNOPSIS

=head1 DESCRIPTION

Run-mode to handle requests for user-defined strain groups

=head1 COPYRIGHT

This work is released under the GNU General Public License v3  http://www.gnu.org/licenses/gpl.htm

=head1 AUTHOR

Matt Whiteside (matthew.whiteside@phac-aspc.gov.gc)

=cut

package Modules::Collections;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use parent 'Modules::App_Super';
use Modules::FormDataGenerator;
use HTML::Template::HashWrapper;
use CGI::Application::Plugin::AutoRunmode;
use Log::Log4perl qw/get_logger/;
use Modules::GenomeWarden;
use JSON;


=head2 setup

Run-mode initialization

=cut

sub setup {
	my $self = shift;

	# Logger
	my $logger = Log::Log4perl->get_logger();
	$logger->info("Logger initialized in Modules::StrainGroup");

}