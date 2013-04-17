#!/usr/bin/perl

=pod

=head1 NAME

Modules::FastaFileWrite - A class that provides the following functionality:

=head1 SYNOPSIS

	use Modules::FastaFileWrite;
	...

=head1 DESCRIPTION

This module can be called to write out whole genomes to files selected from the multi strain selection form on the website.
The fasta files will then be passed to the Panseq analysis platform for statistical analysis.

=head1 ACKNOWLEDGEMENTS

Thanks.

=head1 COPYRIGHT

This work is released under the GNU General Public License v3  http://www.gnu.org/licenses/gpl.html

=head1 AVAILABILITY

The most recent version of the code may be found at:

=head1 AUTHOR

Akiff Manji (akiff.manji@gmail.com)

=head1 Methods

=cut

package Modules::FastaFileWrite;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Log::Log4perl;
use Carp;

#object creation
sub new {
	my ($class) = shift;
	my $self = {};
	bless( $self, $class );
	$self->initialize(@_);
	return $self;
}

=head2 _initialize

Initializes the logger.
Assigns all values to class variables.

=cut

sub _initialize {
my ($self) = shift;

#logging
$self->logger(Log::Log4perl->get_logger());
$self->logger->info("Logger initialized in Modules::FastaFileWrite");

my %params = @_;

}

=head2 logger 

Stores a logger object for the module.

=cut

sub logger {
	my $self = shift;
	$self->{'_logger'} = shift // return $self->{'_logger'}
}

1;