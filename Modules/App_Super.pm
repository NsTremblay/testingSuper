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
use Log::Log4perl qw(:easy);

# get script location via File::Basename
my $SCRIPT_LOCATION = dirname(__FILE__);

# Initialize a basic root logger
# Note: over-write this in child classes if you want to direct the output somewhere
Log::Log4perl->easy_init($DEBUG);

=head2 cgiapp_init



=cut

sub cgiapp_init {
	my $self = shift;

	my $logger = Log::Log4perl->get_logger;
	
	$logger->debug('Initializing CGI::Application in App_Super');

	# Load config options
	#$self->config_file($SCRIPT_LOCATION.'/genodo.cfg');
	$self->config_file($SCRIPT_LOCATION.'/chado_db_test.cfg');

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
		RENDER_LOGIN              => \&render_login
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
 			$$output_ref =~ s|gg_username|<a class="navbar-link" style="padding-left:10px" href="/user/edit_account">$username</a>&nbsp;(<a class="navbar-link" href="/user/logout">Sign out</a>)|;
 			
 			# Enable any links in nav bar that require user to be logged in.
 			
 			# Genome uploader requires user to be logged in.
 			my $authen_gu = 
 			q|<ul class="dropdown-menu" role="menu" aria-labelledby="drop1">
            <li role="presentation"><a role="menuitem" tabindex="-1" href="/genome_uploader">Upload a genome</a></li>
			<li role="presentation" class="divider"></li>
			<li role="presentation"><a role="menuitem" tabindex="-1" href="/user/add_access">Grant access to an uploaded genome</a></li>
			<li role="presentation"><a role="menuitem" tabindex="-1" href="/user/edit_access">Change access to uploaded genomes</a></li>
            </ul>|;
            
            $$output_ref =~ s|gg_genome_uploader|$authen_gu|;
            
                       
		} else {
        	# User is not logged in
        	
			if($self->get_current_runmode ne 'authen_login') {
				# User has not yet clicked the login link
                
                # Display link to login page
				$$output_ref =~ s|gg_username|<a class="navbar-link" style="padding-left:10px" href="/user/login">Sign in</a>|;
				
            	# Show but disable any links in nav bar that require user to be logged in.
 			
	 			# Genome uploader requires user to be logged in.
	 			my $notauthen_gu = 
	 			q|<ul class="dropdown-menu" role="menu" aria-labelledby="drop1">
	 			<li role="presentation"><a role="menuitem" tabindex="-1" href="/user/login">These features require login</a></li>
	            <li role="presentation"><a style="color:#C0C0C0" role="menuitem" tabindex="-1" href="#">Upload a genome</a></li>
				<li role="presentation" class="divider"></li>
				<li role="presentation"><a style="color:#C0C0C0" role="menuitem" tabindex="-1" href="#">Grant access to an uploaded genome</a></li>
				<li role="presentation"><a style="color:#C0C0C0" role="menuitem" tabindex="-1" href="#">Change access to uploaded genomes</a></li>
	            </ul>|;
            
            	$$output_ref =~ s|gg_genome_uploader|$notauthen_gu|;
			}
        }
        
		# Print status param as alert box on home page (this only works on the home page).
		if($self->get_current_runmode eq $self->home_rm) {
	        my $status;
	        my $html_block = '<div class="row-fluid" style="margin-top: 10px; margin-bottom: 20px;">'.
	        				 '<div class="span6 offset3">'.
	        				 '<div class="alert">'.
	        				 '<button type="button" class="close" data-dismiss="alert">&times;</button>';
	        				
	        if($status = $self->param('status')) {
	        		$html_block .= $status.'</div></div></div>';
	                $$output_ref =~ s|<\!-- gg_status_div -->|$html_block|;
	        } elsif($status = $self->session->param('status')) {
	        		$html_block .= $status.'</div></div></div>';
	                $$output_ref =~ s|<\!-- gg_status_div -->|$html_block|;
	                $self->session->clear('status');
	        }
		}            
		
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
	
	return '/home';
}

=head2 home_rm

Home page run-mode

=cut
sub home_rm {
	
	return 'home';
}

=head2 script_location

Accessor for child classes

=cut
sub script_location {
	
	return $SCRIPT_LOCATION;
}
=head2 logger

=cut

sub logger {
	my $self=shift;
	$self->{'_logger'} = shift // return $self->{'_logger'};
}

=head2 script_location

Create HTML for login form

=cut
sub render_login {
	my $self = shift;

	my $template = $self->load_tmpl('login_form.tmpl', die_on_bad_params => 0);
	$template->param( destination => $self->home_page );

	return $template->output();
}

=head2 getGenomes

Queries the database to return list of genomes available to user.

Method is used to populate forms with a list of public and
private genomes.

=cut
sub getGenomes {
    my $self = shift;
    
    # Return public genome names as list of hash-refs
    my $genomes = $self->dbixSchema->resultset('GenomeName')->search({},
    	{
    		result_class => 'DBIx::Class::ResultClass::HashRefInflator',
    		columns => [qw/feature_id uniquename/],
    	}
    );
 	
 	my @publicFormData = $genomes->all;
 	
 	# Get private list (or empty list)
 	my $privateFormData = $self->privateGenomes();
 	
    # Return two lists
    return(\@publicFormData, $privateFormData);
}


=head2 privateGenomes

Queries the database to return list of private uploaded genomes available to user.

User must be logged in. If none available, returns empty list.

=cut
sub privateGenomes {
	my $self = shift;
	
	if($self->authen->is_authenticated) {
		# user is logged in
		
		# Return private genome names as list of hash-refs
		# Need to check view permissions for user
		my $genomes = $self->dbixSchema->resultset('PrivateGenomeName')->search(
			{
				'login.username' => $self->authen->username
			},
	    	{
	    		result_class => 'DBIx::Class::ResultClass::HashRefInflator',
	    		columns => [qw/feature_id uniquename/],
	    		join => {'upload' => { 'permissions' => 'login'} }
	    	}
	    );
	    
	    my @privateFormData = $genomes->all;
	    
	    return \@privateFormData;
		
	} else {
		return [];
	}
}

1;

