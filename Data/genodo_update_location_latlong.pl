#!/usr/bin/perl

use strict;
use warnings;

use Geo::Coder::Google;
use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../";
use Database::Chado::Schema;
use Carp qw/croak carp/;
use Config::Simple;
use DBIx::Class::ResultSet;
use DBIx::Class::Row;

=head1 NAME

$0 - Updates all locations in genodo db with lat long coordinates.

=head1 SYNOPSIS

  % genodo_update_location_latlong.pl [options] 

=head1 COMMAND-LINE OPTIONS

 --config         Specify a .conf containing DB connection parameters.

=head1 DESCRIPTION

A one time use script to update all the locations currently in genodo with latlong coordinates.
User must provide connection parameters for the database in the form of a config file.

=head1 AUTHOR

Akiff Manji

=cut

my ($CONFIG, $DBNAME, $DBUSER, $DBHOST, $DBPASS, $DBPORT, $DBI);

GetOptions(
	'config=s'      => \$CONFIG,
	) or ( system( 'pod2text', $0 ), exit -1 );

# Connect to DB
croak "Missing argument. You must supply a configuration filename.\n" . system ('pod2text', $0) unless $CONFIG;

if(my $db_conf = new Config::Simple($CONFIG)) {
	$DBNAME    = $db_conf->param('db.name');
	$DBUSER    = $db_conf->param('db.user');
	$DBPASS    = $db_conf->param('db.pass');
	$DBHOST    = $db_conf->param('db.host');
	$DBPORT    = $db_conf->param('db.port');
	$DBI       = $db_conf->param('db.dbi');
} 
else {
	die Config::Simple->error();
}

my $dbsource = 'dbi:' . $DBI . ':dbname=' . $DBNAME . ';host=' . $DBHOST;
$dbsource . ';port=' . $DBPORT if $DBPORT;

my $schema = Database::Chado::Schema->connect($dbsource, $DBUSER, $DBPASS) or croak "Could not connect to database.";

# Need to first pull all the strains that have location data.
# Store the featureprop_id in a table so that they can be updated easily.
my @locationList;

my $locationFeaturePropCount = $schema->resultset('Featureprop')->count({'type.name' => 'isolation_location'},{column  => [qw/me.feature_id me.value type.name/],join => ['type']});

print "\t...Found $locationFeaturePropCount locations in the database\n";
sleep(2);

my $locationFeatureProps = $schema->resultset('Featureprop')->search(
	{'type.name' => 'isolation_location'},
	{
		column  => [qw/me.feature_id me.value type.name/],
		join        => ['type']
	}
	);

#Create a new global geocoder
my $googleGeocoder = Geo::Coder::Google->new(apiver => 3);

while (my $locationRow = $locationFeatureProps->next) {
	my %location;
	my $locationFeatureId = $locationRow->featureprop_id;
	my $markedUpLocation = $locationRow->value;

	## Need to parse out <markup></markup> tags for geocoding.
	my $noMarkupLocation = $markedUpLocation;
	$noMarkupLocation =~ s/(<[\/]*location>)//g;
	$noMarkupLocation =~ s/<[\/]+[\w\d]*>//g;
	$noMarkupLocation =~ s/<[\w\d]*>/, /g;
	$noMarkupLocation =~ s/, //;
	#print $noMarkupLocation . "\n";

	$location{'featureprop_id'} = $locationFeatureId;
	$location{'location'} = $noMarkupLocation;
	push(@locationList , \%location);
}

print "\t...Ready to convert " . scalar(@locationList) . " locations to lat long coordinates\n";

#List that will store already generated latlongs so that duplicate geocoding calls are not made.
my %coordinates;

foreach my $locationToConvert (@locationList) {
	#First check to see if the location exists in the list.
	print "Converting " . $locationToConvert->{'location'} . " to coordinates\n";
	#Need to change this next line;
	my %foundCoordinate = (grep $_ eq $locationToConvert->{'location'} , %coordinates);
	if (!%foundCoordinate) {
		print "\tCalling geocoder\n";
		my $latlong = $googleGeocoder->geocode(location => $locationToConvert->{'location'});
		#print %{$latlong->{geometry}->{location}}->{lat} . "\n";
		#print %{$latlong->{geometry}->{location}}->{lng} . "\n";
		#print %{$latlong->{geometry}->{viewport}->{southwest}}->{lat} . "\n";
		#print %{$latlong->{geometry}->{viewport}->{southwest}}->{lng} . "\n";
		#print %{$latlong->{geometry}->{viewport}->{northeast}}->{lat} . "\n";
		#print %{$latlong->{geometry}->{viewport}->{northeast}}->{lng} . "\n";
		#$newCoordinate{$locationToConvert->{'location'}} = $latlong;
		$coordinates{$locationToConvert->{'location'}} = $latlong;
		print scalar(keys %coordinates) . "\n";
		sleep(2);
	}
	else{
		#print %{$foundCoordinate{$locationToConvert->{'location'}}}->{geometry}->{location}->{lat} . "\n";
		#print %{$foundCoordinate{$locationToConvert->{'location'}}}->{geometry}->{location}->{lng} . "\n";
	}
}

#Let the geocode function sleep for 2 seconds before the next call,
#because Google rate-limits the number of calls that can be done and will return an error.
#sleep(2);