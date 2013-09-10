#!/usr/bin/env perl

=pod

=head1 NAME

Modules::MapExample

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
use Modules::FormDataGenerator;

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
	my $template = $self->load_tmpl( 'map_example.tmpl' , die_on_bad_params=>0 );
	my $formDataGenerator = Modules::FormDataGenerator->new();
 	$formDataGenerator->dbixSchema($self->dbixSchema);
	my ($pubDataRef, $priDataRef , $strainJsonDataRef) = $formDataGenerator->getFormData();
	$template->param(FEATURES=>$pubDataRef);

	return $template->output();
}

sub map_multi_markers : Runmode {
	my $self = shift;
	my @markerList;
	my $locationFeatureProps = $self->dbixSchema->resultset('Featureprop')->search(
		{'type.name' => 'isolation_location'},
		{
			column  => [qw/me.feature_id me.value type.name feature.name/],
			join        => ['type' , 'feature'],
			order_by => ['me.value']
		}
		);
	while (my $locationRow = $locationFeatureProps->next) {
		my %newLocation;

		$newLocation{'feature_id'} = $locationRow->feature_id;
		$newLocation{'genome_name'} = $locationRow->feature->name;

		#Parse out location name
		my $markedUpLocation = $1 if $locationRow->value =~ /(<location>[\w\d\W\D]*<\/location>)/;
		my $noMarkupLocation = $markedUpLocation;
		$noMarkupLocation =~ s/(<[\/]*location>)//g;
		$noMarkupLocation =~ s/<[\/]+[\w\d]*>//g;
		$noMarkupLocation =~ s/<[\w\d]*>/, /g;
		$noMarkupLocation =~ s/, //;

		$newLocation{'location'} = $noMarkupLocation;

		#Parse out center latlng
		my %center;
		my $markedUpCenter = $1 if $locationRow->value =~ /(<center>[\w\d\W\D]*<\/center>)/;
		my $noMarkupCenter = $markedUpCenter;
		$noMarkupCenter =~ s/(<[\/]*center>)//g;
		my $centerLat = $1 if $noMarkupCenter =~ /<lat>([\w\d\W\D]*)<\/lat>/;
		my $centerLng = $1 if $noMarkupCenter =~ /<lng>([\w\d\W\D]*)<\/lng>/;
		$center{'lat'} = $centerLat;
		$center{'lng'} = $centerLng;

		$newLocation{'center'} = \%center;

		#Parse out viewport latlng
		my %viewport;

		my %southwestViewport;
		my $markedUpSWViewport = $1 if $locationRow->value =~ /(<southwest>[\w\d\W\D]*<\/southwest>)/;
		my $noMarkupSWViewport = $markedUpSWViewport;
		$noMarkupSWViewport =~ s/(<[\/]*southwest>)//g;
		my $southwestViewportLat = $1 if $noMarkupSWViewport =~ /<lat>([\w\d\W\D]*)<\/lat>/;
		my $southwestViewportLng = $1 if $noMarkupSWViewport =~ /<lng>([\w\d\W\D]*)<\/lng>/;
		$southwestViewport{'lat'} = $southwestViewportLat;
		$southwestViewport{'lng'} = $southwestViewportLng;

		$viewport{'southwest'} = \%southwestViewport;

		my %northeastViewport;
		my $markedUpNEViewport = $1 if $locationRow->value =~ /(<northeast>[\w\d\W\D]*<\/northeast>)/;
		my $noMarkupNEViewport = $markedUpNEViewport;
		$noMarkupNEViewport =~ s/(<[\/]*northeast>)//g;
		my $northeastViewportLat = $1 if $noMarkupNEViewport =~ /<lat>([\w\d\W\D]*)<\/lat>/;
		my $northeastViewportLng = $1 if $noMarkupNEViewport =~ /<lng>([\w\d\W\D]*)<\/lng>/;
		$northeastViewport{'lat'} = $northeastViewportLat;
		$northeastViewport{'lng'} = $northeastViewportLng;

		$viewport{'northeast'} = \%northeastViewport;

		$newLocation{'viewport'} = \%viewport;
		push(@markerList, \%newLocation);
	}

	my $formDataGenerator = Modules::FormDataGenerator->new();
 	$formDataGenerator->dbixSchema($self->dbixSchema);
 	my $multiMarkerHashRef = $formDataGenerator->_getJSONFormat(\@markerList);
 	return $multiMarkerHashRef;
}

1;