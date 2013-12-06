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
use IO::File;
use File::Temp;
use JSON;

#All logging to STDERR to the file specified
open(STDERR, ">>/home/genodo/logs/group_wise_comparisons.log") || die "Error stderr: $!";

my ($CONFIG, $DBNAME, $DBUSER, $DBHOST, $DBPASS, $DBPORT, $DBI);
my ($USERCONFIG, $USERNAME, $USERREMOTEADDR, $USERSESSIONID, $USERJOBID, $USERGP1STRAINIDS, $USERGP2STRAINIDS, $USERGP1STRAINNAMES, $USERGP2STRAINNAMES, $GEOSPATIAL);

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
if (my $user_conf = new Config::Simple($USERCONFIG)) {
	$USERNAME = $user_conf->param('user.username');
	$USERREMOTEADDR = $user_conf->param('user.remote_addr');
	$USERSESSIONID = $user_conf->param('user.session_id');
	$USERJOBID = $user_conf->param('user.job_id');
	$USERGP1STRAINIDS = $user_conf->param('user.gp1IDs');
	$USERGP2STRAINIDS = $user_conf->param('user.gp2IDs');
	$USERGP1STRAINNAMES = $user_conf->param('user.gp1Names');
	$USERGP2STRAINNAMES = $user_conf->param('user.gp2Names');
	$GEOSPATIAL = $user_conf->param('user.geospatial');
}
else {
	die Config::Simple->error();
}

my $dbsource = 'dbi:' . $DBI . 'dbname=' . $DBNAME . ';host=' . $DBHOST;
$dbsource . ';port=' . $DBPORT if $DBPORT;

my $schema = Database::Chado::Schema->connect($dbsource, $DBUSER, $DBPASS);

if (!$schema) {
	die "Could not connect to database: $!\n";
}