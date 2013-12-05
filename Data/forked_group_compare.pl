#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin/../";
use Database::Chado::Schema;
use Modules::FET;
use Carp qw/croak carp/;
use Config::Simple;
use DBIx::Class::ResultSet;
use DBIx::Class::Row;
use DBI;
use IO::File;
use IO::All;
use File::Temp;

#All logging to STDERR to the file specified
open(STDERR, ">>/home/genodo/logs/group_wise_comparisons.log") || die "Error stderr: $!";

my ($CONFIG, $DBNAME, $DBUSER, $DBHOST, $DBPASS, $DBPORT, $DBI, $mailUname, $mailPass);
my ($USERCONFIG, $USEREMAIL, $USERGP1STRAINIDS, $USERGP2STRAINIDS, $USERGP1STRAINNAMES, $USERGP2STRAINNAMES, $SESSIONID, $REMOTEADDRESS);

GetOptions('config=s' => \$CONFIG, 'user_config=s' => \$USERCONFIG) or (exit -1);
croak "Missing db config file\n" unless $CONFIG;
croak "Missing user specific config file\n" unless $USERCONFIG;

if(my $db_conf = new Config::Simple($CONFIG)) {
	$DBNAME = $db_conf->param('db.name');
	$DBUSER = $db_conf->param('db.user');
	$DBPASS = $db_conf->param('db.pass');
	$DBHOST = $db_conf->param('db.host');
	$DBPORT = $db_conf->param('db.port');
	$DBI = $db_conf->param('db.dbi');
}
else {
	die Config::Simple->error();
}

#Set user config params here


my $dbsource = 'dbi:' . $DBI . 'dbname=' . $DBNAME . ';host=' . $DBHOST;
$dbsource . ';port=' . $DBPORT if $DBPORT;

my $schema = Database::Chado::Schema->connect($dbsource, $DBUSER, $DBPASS);

if (!$schema) {
	die "Could not connect to database: $!\n";
}