#!/usr/bin/env perl

package Modules::Shiny;

#Shiny API

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use parent 'Modules::App_Super';
use Modules::FormDataGenerator;
use HTML::Template::HashWrapper;
use CGI::Application::Plugin::AutoRunmode;
use Log::Log4perl qw/get_logger/;
use Sequences::GenodoDateTime;
use Phylogeny::Tree;
use Modules::LocationManager;
use JSON;
use Time::HiRes;
use Switch;

=head2 setup

Defines the start and run modes for CGI::Application and connects to the database.

=cut

sub setup {
    my $self=shift;
    
    get_logger->info("Initializing Modules::Shiny");

}

=head2 data

Run-mode interface to the Shiny server. 

Returns user groups and genome meta-data
Saves updates to user groups.

=cut
sub data : Runmode {
    my $self = shift;

    my $q = $self->query();

    #my $SHINYSESSID = $q->param('CGISESSID');
    #my $SHINYURI = $q->param('uri');
    #my $SHINYUSER = $q->param('user');

    my $session_id = $self->session->id();
    get_logger->debug("Session ID: $session_id");

    my $formMethod = $ENV{'REQUEST_METHOD'};

    # Check user is logged in
    my $username = $self->authen->username;

    my $msg = self->authen->is_athenticated ? "Username: $username" : "Not logged in";
    get_logger->debug($msg);
    

    if ($formMethod eq 'GET') {
        print STDERR "\nGET method called\n\n";
        my $user_data_json = $self->_getUserData($username, $session_id);
        return $user_data_json;
    }
    elsif ($formMethod eq 'POST') {
        print STDERR "\nPOST method called\n\n";
        #my $user_genomes = $q->param('genome_id');
        my $user_groups = $q->param('groups');
        my $status_json = $self->_saveUserData($username, $user_groups);
        return $status_json;
    }
    else {
        my $status = {error => "contact database administrator"};
        return encode_json($status);
    }
}


# Helper methods
sub _getUserData {
    my ($self, $username, $CGISESSID) = @_;

    my $shiny_data = {
        user => $username,
        'CGISESSID' => $CGISESSID,
    };

    _returnError($shiny_data, 'User not logged in');
    
    # DB Accessor object
    my $fdg = Modules::FormDataGenerator->new();
    $fdg->dbixSchema($self->dbixSchema);

    # Location Manager object for parsing geocoded addresses
    my $lm = Modules::LocationManager->new();
    $lm->dbixSchema($self->dbixSchema);

    # Get genome data
    my $public_meta = $fdg->_runGenomeQuery(1);
    my $private_meta = $fdg->_runGenomeQuery(0,$username);

    # Initialize variables
    my %genome_ids;
    my $i = 0;
    map { $genome_ids{$_} = $i; $i++ } keys %{$public_meta}, keys %{$private_meta};

    # Empty list
    my @empty = (undef) x $i;

    # Meta-data lists
    my $meta_categories;
    foreach my $term (keys %{$fdg->metaTerms}, keys %{$fdg->subtypes}) {
        $meta_categories->{$term} = [ @empty ];
    }

    my $extra_date_categories = {
        'isolation_year' => [ @empty ],
        'isolation_month' => [ @empty ],
        'isolation_day' => [ @empty ],
    };
    my $extra_location_categories = {
        'isolation_country' => [ @empty ],
        'isolation_province_state' => [ @empty ],
        'isolation_city' => [ @empty ]
    };

    # Group lists
    my $group_lists;
    my $group_hashref = $fdg->userGroupList($username);
    foreach my $name (values %$group_hashref) {
        if(defined $group_lists->{$name}) {
            # Future group development will allow users to assign groups to categories
            # allowing possible groups in different categories to have same name. Currently
            # all groups are part of the default category 'Individuals' and should be unique,
            # but check will make sure groups in this hash are not clobbered at any point in the future.
            die "Error: group name collision. Multiple custom user-defined genome groups with same name.";
        }

        $group_lists->{$name} = [ @empty ];
    }


    foreach my $genome_id (keys %genome_ids) {

        my $genome_obj = $public_meta->{$genome_id} || $private_meta->{$genome_id};
        my $index = $genome_ids{$genome_id};

        foreach my $meta_cat (keys %$meta_categories) {
            switch ($meta_cat) {
                case 'isolation_date' {
                    if($genome_obj->{$meta_cat}) {
                        # Save full date
                        my $date_string = join('', @{$genome_obj->{$meta_cat}});
                        $meta_categories->{$meta_cat}->[$index] = $date_string;

                        # Save date parts
                        my @date = split('-', $date_string);
                        $extra_date_categories->{'isolation_year'}->[$index] = $date[0];
                        $extra_date_categories->{'isolation_month'}->[$index] = $date[1];
                        $extra_date_categories->{'isolation_day'}->[$index] = $date[2];
                    }
                }
                case 'isolation_location' {
                    if($genome_obj->{$meta_cat}) {
                        # Save full address
                        my $location_ref = decode_json($genome_obj->{$meta_cat}->[0]);
                        $meta_categories->{$meta_cat}->[$index] = $location_ref->{'formatted_address'};

                        # Save address components
                        my $parsed_location_ref = $lm->parseGeocodedAddress($location_ref);
                        foreach (keys %$extra_location_categories) {
                            $extra_location_categories->{"$_"}->[$index] = $parsed_location_ref->{"$_"} if $parsed_location_ref->{"$_"};
                        }
                    }
                }
                else {
                    if($genome_obj->{$meta_cat}) {
                        my $value = ref($genome_obj->{$meta_cat}) eq 'ARRAY' ? join(' ', @{$genome_obj->{$meta_cat}}) : $genome_obj->{$meta_cat};
                        $meta_categories->{$meta_cat}->[$index] = $value;
                    }
                }
            }
        }

        if($genome_obj->{groups}) {
            foreach my $group_id (@{$genome_obj->{groups}}) {
                my $group_name = $group_hashref->{$group_id};
                $group_lists->{$group_name}->[$index] = 1;
            }
        }
    }

    $shiny_data->{'data'}{keys %$meta_categories} = values %$meta_categories;
    $shiny_data->{'data'}{keys %$extra_date_categories} = values %$extra_date_categories;
    $shiny_data->{'data'}{keys %$extra_location_categories} = values %$extra_location_categories;
    $shiny_data->{'groups'}{keys %$group_lists} = values %$group_lists;
    $shiny_data->{'status'} = "User data retrieved for $username";

    return encode_json($shiny_data);
}

sub _returnError {
    my $shiny_data = shift;
    my $msg = shift;

    $shiny_data->{error} = $msg;

    return encode_json($shiny_data)
}

sub _saveUserData {
    # TODO: Test this
    my ($self, $_userName, $_userGroups) = @_;

    #print STDERR $_userGroups . "\n";

    my $user_groups_obj = decode_json($_userGroups);

    #print STDERR $user_groups_obj . "\n";

    my $status = {};

    unless ($_userName) {    
        $status->{error} = "User not logged in";
        return encode_json($status);
    }

    my $timestamp = localtime(time);

    my $userGroupQuery = $self->dbixSchema->resultset('UserGroup')->find({username => $_userName});

    if ($userGroupQuery) {
        $userGroupQuery->update(
        {
            last_modified => "$timestamp",
            user_groups => encode_json($user_groups_obj)
            });
    }
    else {
        $userGroupQuery = $self->dbixSchema->resultset('UserGroup')->create(
        {
            username => $_userName,
            last_modified => "$timestamp",
            user_groups => encode_json($user_groups_obj)
            });
    }

    $status->{status} = "User data updated";
    return encode_json($status);
}

1;