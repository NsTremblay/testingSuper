#!/usr/bin/perl

package Modules::User;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use parent 'Modules::App_Super';
use Carp qw/croak carp/;
use CGI::Application::Plugin::ValidateRM;
use CGI::Application::Plugin::AutoRunmode;
use Data::FormValidator::Constraints qw(email FV_eq_with FV_length_between);
use Digest::MD5 qw(md5_base64);
use Log::Log4perl qw/get_logger/;

my $sl = Modules::App_Super::script_location();
Log::Log4perl->init($sl."/logger.conf");
my $logger = get_logger('User');

my $dbic;

sub setup {
	my $self = shift;
	
	$dbic = $self->dbixSchema;
	
	$self->authen->protected_runmodes('hello');
}

=head2 logout

Currently a logout is only triggered when a authen_logout param is caught. This method provides another
mechanism of logging out by specifying a logout run-mode.

=cut 
sub logout : Runmode {
	my $self = shift;
	
	$self->authen->logout;
	
	$self->redirect($self->home_page);
}

sub hello : Runmode {
	my $self = shift;
	my $template = $self->load_tmpl ( 'hello.tmpl', die_on_bad_params=>0 );
	return $template->output();
}

=head2 edit_account

Display page to allow user to edit/update user info.

Requires authentication, and is therefore a protected run-mode.

=cut 

sub edit_account : Runmode {
	my $self = shift;
	my $errs = shift;

	my $t = $self->load_tmpl('user_form.tmpl', die_on_bad_params => 0);

	# Retrieve existing user data from database
	my $user_rs = $self->dbixSchema->resultset('Login')->find( { username => $self->authen->username } );

	croak 'User not found in database' unless $user_rs; # should not happen because user is already authenticated
	  
	# populate template with current field values
	my $fields = &_user_fields;
	foreach my $field ( keys  %$fields ) {
		next if $field eq 'u_password';    # leave password field blank
		
		my $column = $fields->{$field};
		$t->param( $field, $user_rs->$column );
	}

	$t->param(rm => '/user/update_account');
	$t->param( title => 'My Account' );
	$t->param($errs) if $errs;             # created by rm update
	$t->output;
}

=head2 update

Update user account.  Return to user form page if there are errors.

=cut

sub update_account : Runmode {
	my $self = shift;
	
	# Prepare rules for edit user form
	my $rules = &_dfv_common_rules;  # Builds on general rules for form
	
	$rules->{required} = [qw(u_first_name u_last_name u_email)]; # required fields
	$rules->{dependency_groups}->{password_group} = [qw/u_password password_confirm/]; # password can be both black or both filled in
    
    # Validate user_form for update operation
	my $dfv_results = $self->check_rm('edit_account', $rules) ||
		return $self->check_rm_error_page;
	
	# No errors, update user acount
	my $q = $self->query;
	my $fields = &_user_fields;
	
	my $username = $self->authen->username;
	my $user_rs = $dbic->resultset('Login')->find( { $fields->{u_username} => $username } ) or croak "Username $username not found in database ($!).\n";
	
	foreach my $field (keys %$fields) {
		
		next if $field eq 'u_username'; # Cannot update username
		next if $q->param($field) eq ""; # Skip empty fields, nothing to update
		croak "Invalid edit account form field $field.\n" unless $dfv_results->valid($field);
		
		my $value = $q->param($field);
		
		if($field eq 'u_password') {
			#Encode password
			$user_rs->set_column($fields->{$field}, _encode_password($value));
		} else {
			$user_rs->set_column($fields->{$field}, $value);
		}
	}
	# Update record in DB
	$user_rs->update or croak "Update of user information in database failed ($!).\n";
	
	$self->session->param( status => '<strong>Success!</strong> Account updated.' );
	$self->redirect($self->home_page);
}
	

=head2 new_account

Display page to allow user to create account.  If user is logged in, they will be sent to the edit page.

=cut 

sub new_account : StartRunmode {
	my $self = shift;
	my $errs = shift; # errors will be passed from run-mode create (forcing user to try again)
	
	$logger->debug('Displaying new account form.');

	if ( $self->authen->is_authenticated ) {

		# User is logged in. Forward to the edit page
		return $self->edit_account;
	}

	my $t = $self->load_tmpl('user_form.tmpl', die_on_bad_params => 0);
	
	$t->param( new_user => 1 ); # The same form is used to create and edit user accounts, this param sets up new account view in template.
	$t->param( rm => '/user/create_account' );
	$t->param( title => 'My Account' );
	$t->param($errs) if $errs;    # errors from run-mode create
	$t->output;
}

=head2 create_account

Create new user account.  Return to user form page if there are errors.

=cut 

sub create_account : Runmode {
	my $self = shift;
	
	$logger->debug('Initiating a user creation.');
	
	# Prepare rules for new user form
	my $rules = &_dfv_common_rules;  # Builds on general rules for form
	
    $rules->{required} = [qw(u_username u_password password_confirm u_first_name u_last_name u_email)];
    
	$rules->{constraint_methods}->{u_username} = [
		\&_valid_username,
		\&_username_does_not_exist,
	];
	
	$rules->{msgs}->{constraints}->{username_does_not_exist} = 'username exists';
	
	# Validate user_form for create operation
	my $dfv_results = $self->check_rm( 'new_account', $rules ) ||
		return $self->check_rm_error_page;
		
	# No errors, create user acount
	my $q = $self->query;
	my $fields = &_user_fields;
	my %create_hash;
	foreach my $field (keys %$fields) {
		croak "Missing new account form field $field.\n" if $q->param($field) eq ""; # There should be no empty fields at this point, but just in case
		croak "Invalid new account form field $field.\n" unless $dfv_results->valid($field);
		my $value = $q->param($field);
		
		if($field eq 'u_password') {
			#Encode password
			$create_hash{ $fields->{$field} } = _encode_password($value);
		} else {
			$create_hash{ $fields->{$field} } = $value;
		}
	}
	# Insert into DB
	$dbic->resultset('Login')->create(\%create_hash) or croak "Insertion of new user into database failed ($!).\n";
	
	# Login automatically for user
	my $a = $self->authen;
	my $authentication_form_params = $a->credentials;
	$q->param( $authentication_form_params->[0] => $q->param('u_username') );
	$q->param( $authentication_form_params->[1] => $q->param('u_password') );
	$a->{initialized} = 0;    # force reinitialization, hence storage of login
	$a->initialize;
	$self->session->param( status => '<strong>Success!</strong> Account created.' );
	
	# Go to main page
	$self->redirect($self->home_page);
}

=head2 forgot_password 

Display page for forgotten password

=cut
sub forgot_password : RunMode {
	my $self = shift;
	my $errs = shift;
	
	my $t = $self->load_tmpl('forgot_password_form.tmpl', die_on_bad_params => 0);
    $t->param(rm => '/user/email_password');
	$t->param(title => 'Forgot Password');
	$t->param($errs) if $errs; # created by run-mode email_password
	$t->output
	
}

=head2 email_password 

Email user new password. Return to forgot password page if there are errors.

=cut
sub email_password : RunMode {
	my $self = shift;
	
	# Validate forgot password form
	my $results = $self->check_rm('forgot_password', &_dfv_forgot_password_rules) ||
		return $self->check_rm_error_page;
	
	# Obtain exisiting password, revert to this password if operation fails
	my $username = $self->query->param('u_username');
	my $user_rs = $dbic->resultset('Login')->find( { username => $username } ) or croak "Username $username not found in database ($!).\n";
	
	my $existing_password = $user_rs->password;
	
	# Generate a new password and set user password to new value
	my $new_password = &_new_password;
	$user_rs->password(_encode_password($new_password));
	$user_rs->update or croak "Unable to update password for user $username ($!).\n";
	
	# Send email with new password to user
	require Mail::Sendmail;
	
	my %mail = ( 
				From    => 'test@test.org',
				To		=> $user_rs->email,
                Subject => 'Password reset',
				'content-type' => "text/html;\n\n",
				Message => '<html>Your new password is <b>'.$new_password.'</b>'
					.'<br>You may want to change your password to something more memorable after you log in'
					.'</html>'
	);
	
	if($ENV{HTTP_HOST} =~ /184\.64\.136\.138/) {
		$self->session->param(
			status => 
			'<strong>Heads Up!</strong> A new password has been sent to your email address: '. $user_rs->email
			.'.<br/>Since you are on the testing site, the email won\'t '
			.' <br/>be sent, so here is the new password: '. $new_password
		);
		
	} else {
		if(!Mail::Sendmail::sendmail(%mail)) {
			# Email failed, revert to old password
			$user_rs->password($existing_password);
			$user_rs->update or croak "Unable to restore password for user $username ($!).\n";
			
			my $err = $Mail::Sendmail::error;
			croak "Unable to send new password to $username. Password not reset ($err).";
		}
	       
		$self->session->param( status => '<strong>Check your Email!</strong> a new password has been sent to your email address.');
	}
	
	
	$self->redirect($self->home_page);
}

###########
## Methods to validate user form
###########

=head2 _dfv_common_rules

Update and new account form must satisfy these rules

=cut
sub _dfv_common_rules {
        return {
                filters  => [qw(trim strip)],
                constraint_methods => {
                        u_password => FV_length_between(6,10),
                        password_confirm => FV_eq_with('u_password'),
                        u_first_name => \&_valid_name,
                        u_last_name => \&_valid_name,
                        u_email => email(),
                },
                msgs => {
                        format => '<span class="dfv_errors">%s</span>',
                        any_errors  => 'some_errors',
                        prefix  => 'err_',
                        constraints => {
                                'eq_with'        => 'passwords must match',
                                'length_between' => 'character count',
                        }
                },
        }
}

=head2 _valid_name 

Valid names can have ' - . spaces and letters are valid, e.g.,  First   Last-withHyphen Jr.

=cut
sub _valid_name {
        my $name = pop;
        
        return $name =~ /^[a-zA-Z' \.-]{1,30}$/
}

=head2 _valid_username 

Valid usernames can be at most 20 alphanumeric chars (incl _);

=cut
sub _valid_username {
        my ($dfv, $u_username) = @_;

        $u_username =~ /^\w{1,20}$/
}

=head2 _username_does_not_exist 

Search DB for existing username. Note: setup() sets global $dbic to current dbix::class:schema object

=cut
sub _username_does_not_exist {
	my ($dfv, $u_username) = @_;
	
	$dfv->name_this('username_does_not_exist');
	
	my $rv = $dbic->resultset('Login')->find( { username => $u_username } );
	
	return(!defined($rv));
	
}

=head2 _user_fields

Maps user form params to login table columns
	
=cut
sub _user_fields {
	return { 
		u_username    => 'username',
		u_password    => 'password',
		u_first_name  => 'firstname',
		u_last_name   => 'lastname',
		u_email       => 'email' }
}

=head2 _encode_password 

Encode password

=cut
sub _encode_password {    
	my ($new_val) = @_;
	
	return md5_base64($new_val);        
}

=head2 _username_exists 

Search DB for existing username. Note: setup() sets global $dbic to current dbix::class:schema object

=cut
sub _username_exists {
my ($dfv, $u_username) = @_;
	
	$dfv->name_this('username_exists');
	
	my $rv = $dbic->resultset('Login')->find( { username => $u_username } );
	
	return(defined($rv));
}

=head2 _new_password 

Generate random password for users that have forgotten their password.

=cut
sub _new_password {
        my @chars = (
                'a'..'k','m','n','p'..'z',  '2'..'9',  '!','@','#','$','%','&','*','-',
                'A'..'N',        'P'..'Z');             # skip confusing 1,l,o,0
        my $password = '';
        for (0..7) {
                $password .= $chars[int rand @chars];
        }
        return $password;
}

=head2 _dfv_forgot_password_rules

Forgot password form must satisfy these rules

=cut
sub _dfv_forgot_password_rules {
	return {
		required  => [qw(u_username)],
		filters   => 'trim',
		constraint_methods => {
			u_username => [
				\&_valid_username,
				\&_username_exists,
			],
		},
		msgs => {
			format  => '<span class="dfv_errors">%s</span>',
			prefix   => 'err_',
			constraints => {
				username_exists => 'username does not exist'
        	}
		},
	}
}


1;
