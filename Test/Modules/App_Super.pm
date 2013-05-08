#!/usr/bin/env perl
package Modules::App_Super;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use lib "/usr/local/share/perl/5.10.1/";
use File::Basename;

use parent 'CGI::Application';
use CGI::Application::Plugin::Config::Simple;
use CGI::Application::Plugin::Redirect;
use CGI::Application::Plugin::Session;
use HTML::Template;
use Role::Tiny::With;
with 'Roles::DatabaseConnector';
use Log::Log4perl qw(:easy);
use Carp;

#get script location via File::Basename
my $SCRIPT_LOCATION = dirname(__FILE__);

sub cgiapp_init{
	my $self = shift;
	
	$self->config_file($SCRIPT_LOCATION.'/genodo.cfg');

	$self->connectDatabase(dbi => $self->config_param('db.dbi'),
		dbName => $self->config_param('db.name'),
		dbHost => $self->config_param('db.host'),
		dbPort => $self->config_param('db.port'),
		dbUser => $self->config_param('db.user'),
		dbPass => $self->config_param('db.pass')); 

	#set paths
	#the template path is set using CGI::Application::Dispatch

	#Session information
	$self->session_config(DEFAULT_EXPIRY => '+8h');
	Log::Log4perl->easy_init($DEBUG);
}

sub logger {
	my $self=shift;
	$self->{'_logger'} = shift // return $self->{'_logger'};
}

1;

