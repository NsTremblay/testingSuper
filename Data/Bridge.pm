#!/usr/bin/env perl

=head1 NAME

$0 - Contains several packages needed for accessing Database

=head1 AUTHORS

Matthew Whiteside E<lt>matthew.whiteside@phac-aspc.gc.caE<gt>

Copyright (c) 2014

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

package Data::Bridge;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Modules::GenomeWarden;
use Role::Tiny::With;
with 'Roles::DatabaseConnector';
with 'Roles::CVMemory';
use Log::Log4perl qw(:easy);
use Carp qw/croak/;
use Config::Simple;


# Initialize a basic logger
Log::Log4perl->easy_init($DEBUG);

=head2 _init

=cut

sub new {
	my $class = shift;
	my %arg   = @_;

	my $self  = bless {}, ref($class) || $class;
	
	if($arg{config}) {
		my $config_file = $arg{config};
		

		my $logger = Log::Log4perl->get_logger;
		
		$logger->debug('Initializing Bridge object');

		# Load config options
		my $conf = new Config::Simple($config_file);

		# Set up database connection
		$self->connectDatabase(   dbi     => $conf->param('db.dbi'),
						          dbName  => $conf->param('db.name'),
						          dbHost  => $conf->param('db.host'),
						          dbPort  => $conf->param('db.port'),
						          dbUser  => $conf->param('db.user'),
						          dbPass  => $conf->param('db.pass') 
		);
	}
	elsif($arg{schema}) {
		$self->setDbix($arg{schema});

	}
	else {
		croak "Error: missing parameter: config.";
	}	
	
	return $self;
}

# Return a GenomeWarden object for a user
sub warden {
	my $self = shift;
	my $user = shift;
	my $genomes = shift;
	
	my $warden;
	if($genomes) {
		$warden = Modules::GenomeWarden->new(schema => $self->dbixSchema, genomes => $genomes, user => $user, cvmemory => $self->cvmemory);
		my ($err, $bad1, $bad2) = $warden->error; 
		if($err) {
			# User requested invalid strains or strains that they do not have permission to view
			croak 'Request for uploaded genomes that user does not have permission to view ' .join('', @$bad1, @$bad2);
		}
		
	} else {
		
		$warden = Modules::GenomeWarden->new(schema => $self->dbixSchema, user => $user, cvmemory => $self->cvmemory);
	}
	
	return $warden;
}



