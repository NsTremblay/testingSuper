#!/usr/bin/perl

package Modules::DiplayTest;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Database::Chado::TestSchema; #This is an error with the linter not a pathing issue
use base 'CGI::Application';
use Log::Log4perl qw(:easy);
use Carp;
use Role::Tiny::With;
with 'Roles::DatabaseConnector';

#Set logging level
Log::Log4perl->easy_init($DEBUG);


# #Object creation.

sub new {
	#public method
	my ($class) = shift;
	my $self = {};
	bless ( $self, $class);
	self->_initialize(@_);
	return $self;
}

sub _initialize {
	#private method
	my ($self) = shift;

	#Inititalize the logger
	$self->logger(Log::Log4Perl->get_logger());
	$self->logger->info("Logger has been initialized in Modules::Assays");

	#########################
	#Initialize object fields
	#########################

	my %params = @_;

	#set all parameters on object construction
	foreach my $key(keys %params){
		if($self->can($key)) {
			$self->$key($params{$key});
		}
		else {
			#logconfess calls the confess of Carp package, as well as logging to Log4Perl
			$self->logger->logconfess("$key is not a valid parameter in Module::Assays");
		}
	}
}

#Get/Set for logger. Passes in a new logger from Log4perl and either sets it or returns the existing logger
sub logger {
	#public method
	my ($self) = shift;
	$self->{'_logger'} = shift // return $self->{'_logger'};
}


#dNeed to create a connect method in the new schema that will take these as connection params
# to the local database, or create a role that has the method and let this class implement it.

sub setup{
	#public method
	my $self = shift;

	$self->start_mode('displayTest');
    $self->run_modes('display'=>'displayTest' , 'hello'=>'hello' );

	#connect to the local database
	#	better to have this passed in as a config file
	#Need to have the following methods in this subroutine:
	# 	 mode_param() - set the name of the run mode CGI param.
 	#    start_mode() - text scalar containing the default run mode.
	#    error_mode() - text scalar containing the error mode.
 	#    run_modes() - hash table containing mode => function mappings.
 	#    tmpl_path() - text scalar or array reference containing path(s) to template files.

	$self->connectDatabase(
		{
			'dbi'=>'Pg',
			'dbName'=>'chado_db_test',
			'dbHost'=>'localhost',
			'dbPort'=>'5432',
			'dbUser'=>'postgres',
			'dbPass'=>'postgres'
		}
	);
}

#This will display the home page. Need to set the parameters for the templates so that they get loaded into browser properly
sub displayTest {
	#public method

	my $self = shift;
sub new {
	#public method
	my ($class) = shift;
	my $self = {};
	bless ( $self, $class);
	self->_initialize(@_);
	return $self;
}

sub _initialize {
	#private method
	my ($self) = shift;

	#Inititalize the logger
	$self->logger(Log::Log4Perl->get_logger());
	$self->logger->info("Logger has been initialized in Modules::Assays");

	#########################
	#Initialize object fields
	#########################

	my %params = @_;

	#set all parameters on object construction
	foreach my $key(keys %params){
		if($self->can($key)) {
			$self->$key($params{$key});
		}
		else {
			#logconfess calls the confess of Carp package, as well as logging to Log4Perl
			$self->logger->logconfess("$key is not a valid parameter in Module::Assays");
		}
	}
}
	my $allStrains = $self->dbixSchema->resulset('Feature')->search(
		undef,
			{
				columns=>[ qw/feature_id uniquename/ ]
			}
		);

	# TODO: call subs here to format the data returned from the query.
	
	my $template = $self->load_tmpl( 'display_test.tmpl' , die_on_bad_params=>0 );
	return $template->output();
}

sub _getAllStrains {
	#private method

	my $self = shift;

}

#Need to have a dispatch table with run modes to run this module when we type the web address in the browser.
# if a run mode is not indicated the program will croak().
sub hello {
	my $self = shift;
	my $template = $self->load_tmpl ('hello.tmpl' , die_on_bad_params=>0 );
	return $template->output();
}

1;