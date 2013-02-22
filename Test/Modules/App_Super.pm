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

#get script location via File::Basename
my $SCRIPT_LOCATION = dirname(__FILE__);

sub cgiapp_init{
	my $self = shift;

	#set paths
	#the template path is set using CGI::Application::Dispatch

	#Session information
	$self->session_config(DEFAULT_EXPIRY => '+8h');
	
}

1;

