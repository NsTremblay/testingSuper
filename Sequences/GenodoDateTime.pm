#!/usr/bin/perl

=pod

=head1 NAME

Sequences::GenodoDateTime

=head1 SNYNOPSIS

  my $dateTime = Sequences::GenodoDateTime->parse_datetime($date)

=head1 DESCRIPTION

  This class is designed to parse all the different date formats encountered in genbank 
  files and user uploaded forms.  Implements method parse_datetime which returns a DateTime object.

=head1 COPYRIGHT

This work is released under the GNU General Public License v3  http://www.gnu.org/licenses/gpl.htm

=head1 AVAILABILITY

The most recent version of the code may be found at:

=head1 AUTHOR

Matt Whiteside (mawhites@phac-aspc.gov.ca)

=head1 Methods

=cut

package Sequences::GenodoDateTime;

use strict;
use warnings;
use DateTime::Format::Strptime;

# Genbank 1998, saved as 01-01-1998
my $year = DateTime::Format::Strptime->new(
	pattern   => '%Y',
	locale    => 'en_US',
	time_zone => 'America/Edmonton',
	on_error  => 'croak',
);

# Genbank APR-1991, saved as 01-04-1991
my $monyear = DateTime::Format::Strptime->new(
	pattern   => '%b-%Y',
	locale    => 'en_US',
	time_zone => 'America/Edmonton',
	on_error  => 'croak',
);

# Genbank 15-APR-1991, saved as 15-04-1991
my $daymonyear = DateTime::Format::Strptime->new(
	pattern   => '%d-%b-%Y',
	locale    => 'en_US',
	time_zone => 'America/Edmonton',
	on_error  => 'croak',
);


use DateTime::Format::Builder (
	parsers => { 
		parse_datetime => [
			sub { eval { $daymonyear->parse_datetime($_[1] ) } },
			sub { eval { $monyear->parse_datetime($_[1],  ) } },
      		sub { eval { $year->parse_datetime($_[1] ) } },
      		
		]
	}
);


1;