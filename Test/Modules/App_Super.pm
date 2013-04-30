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
use CGI::Application::Plugin::Authentication;
use Carp qw/croak carp/;
use HTML::Template;
use Role::Tiny::With;
with 'Roles::DatabaseConnector';

# get script location via File::Basename
my $SCRIPT_LOCATION = dirname(__FILE__);

=head2 cgiapp_init



=cut

sub cgiapp_init {
	my $self = shift;


	# Load config options
	$self->config_file($SCRIPT_LOCATION.'/genodo.cfg');

	# Set up database connection
	$self->connectDatabase(   dbi     => $self->config_param('db.dbi'),
					          dbName  => $self->config_param('db.name'),
					          dbHost  => $self->config_param('db.host'),
					          dbPort  => $self->config_param('db.port'),
					          dbUser  => $self->config_param('db.user'),
					          dbPass  => $self->config_param('db.pass') 
	);

	# Set up session tracking
	$self->session_config(
		CGI_SESSION_OPTIONS => [ "driver:PostgreSQL;serializer:Storable", $self->query, 
		                         { ColumnType => "binary",
		                           Handle     => $self->dbh
			                     } ],
		DEFAULT_EXPIRY => '+8h');
	
	# Initialize authentication plugin
	# Redirects to home page after login/logout
	$self->authen->config(
		DRIVER => [ 'DBI',
			DBH         => $self->dbh,
			TABLE       => 'login',
			CONSTRAINTS => {
				'login.username'            => '__CREDENTIAL_1__',
				'MD5_base64:login.password' => '__CREDENTIAL_2__'
			},
		],
		POST_LOGIN_URL            => $self->home_page,
		LOGOUT_URL                => $self->home_page,
		LOGIN_FORM                => {
			REGISTER_URL          => '/user/new_account',
			REGISTER_LABEL        => 'Create account',
			FORGOTPASSWORD_URL    => '/user/forgot_password',
			FORGOTPASSWORD_LABEL  => 'Forgot password?'
		}
	);
	
	
}

=head2 cgiapp_prerun

This method defines a prerun hook.  Used to check if user is trying to login.
Logout behaviour is already handled by CAP::Authentication.

=cut

sub cgiapp_prerun {
	my $self = shift;
	
	# Parameters are used to determine if authentication action has been requested.
	# If authentication param detected, redirect to proper authentication run-mode.
	# Login and logout are handled by CAP::Authentication
    
}

=head2 cgiapp_postrun

This method defines a postrun hook.  User's login status is updated here.

=cut

sub cgiapp_postrun {
	my $self = shift;
	my $output_ref = shift;
	
	
	if($self->header_type eq 'header') {
		# Sending HTML page (not redirect or data file), update user login info on page
		
		my $a = $self->authen;
 
 		if($a->is_authenticated) {
 			# User is logged in
 			
 			# Display current username as link to edit page and logout link
			my $username = $a->username;
 			$$output_ref =~ s|gg_username|<a href="/user/edit_account">$username</a> (<a href="/user/logout">Sign out</a>)|;
                       
		} else {
        	# User is not logged in
        	
			if($self->get_current_runmode ne 'authen_login') {
				# User has not yet clicked the login link
                
                # Display link to login page
				$$output_ref =~ s|gg_username|<a href="/user/login">Sign in</a>|;
			}
        }
        

        my $status;
        if($status = $self->param('status')) {
                $$output_ref =~ s|<\!-- gg_status_div -->|<div id='status_div'><span>$status</span></div>|;
        } elsif($status = $self->session->param('status')) {
                $$output_ref =~ s|<\!-- gg_status_div -->|<div id='status_div'><span>$status</span></div>|;
                $self->session->clear('status');
        }
#        $$output_ref =~ s|zz_\w+||g;  # remove any placeholders that might still be left
#                   # If there is only zz_status_div, the above can be made much faster:
#                   # $$output_ref =~ s|zz_status_div||;
#        $$output_ref .= '<pre>DEBUG stuff: [this line is in BaseCgiApp.pm cgiapp_postrun()]<br />'
#                .$self->dump  # debug
#                
		
	}

}

=head2 teardown

Need to override method to ensure that session information is updated

=cut
sub teardown {
	my $self = shift;
        
	$self->session->flush if $self->session_loaded; # required, auto-flushing may not be reliable. See CGI::Session doc
}


=head2 home_page

URL to home page for redirects

=cut
sub home_page {
	
	return '/start';
}

=head2 script_location

Accessor for child classes

=cut
sub script_location {
	
	return $SCRIPT_LOCATION;
}

1;

