#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Config::Simple;
use Carp;
use FindBin;
use lib "$FindBin::Bin/../";
use Database::Chado::Schema;
use Modules::FormDataGenerator;

=head1 NAME

$0 - Loads meta data for all public genomes into meta table

=head1 SYNOPSIS

  % $0 [options]

=head1 OPTIONS

 --config      INI style config file containing DB connection parameters

=head1 DESCRIPTION

To improve the speed of page loading, meta data (i.e. featureprops such as strain)
are queried once and then saved in a table called meta as a json string.  The json
string needs to be updated anytime the public data changes (relatively infrequent).

=head1 AUTHORS

Matthew Whiteside E<lt>matthew.whiteside@phac-aspc.gc.caE<gt>

Copyright (c) 2013

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

$|=1;

my ($CONFIG, $dbhost, $dbname, $dbport, $dbuser, $dbpass);

GetOptions(
    'config=s' => \$CONFIG,
    'dbname=s' => \$dbname,
    'dbhost=s' => \$dbhost,
    'dbport=i' => \$dbport,
    'dbuser=s' => \$dbuser,
    'dbpass=s' => \$dbpass
);

# Connect to DB
my $dbi = 'Pg';
if($CONFIG) {

	if(my $db_conf = new Config::Simple($CONFIG)) {
		$dbname    = $db_conf->param('db.name');
		$dbuser    = $db_conf->param('db.user');
		$dbpass    = $db_conf->param('db.pass');
		$dbhost    = $db_conf->param('db.host');
		$dbport    = $db_conf->param('db.port');
		$dbi       = $db_conf->param('db.dbi');
	} else {
		die Config::Simple->error();
	}

} else {
	croak "Missing DB connection paramters. Must provide config file or individual parameters." unless $dbname && $dbhost && $dbpass && $dbuser;
}

my $dbsource = 'dbi:' . $dbi . ':dbname=' . $dbname . ';host=' . $dbhost;
$dbsource . ';port=' . $dbport if $dbport;

my $schema = Database::Chado::Schema->connect($dbsource, $dbuser, $dbpass) or croak "Error: could not connect to database.";

# Initialize FDG object
my $fdg = Modules::FormDataGenerator->new();
$fdg->dbixSchema($schema);

# Retrieve and load JSON feature data objects in table
$fdg->loadMetaData();


