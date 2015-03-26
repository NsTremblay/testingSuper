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
use Data::Dumper;

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

    my $msg = $self->authen->is_authenticated ? "Username: $username" : "Not logged in";
    get_logger->debug($msg);
    

    if ($formMethod eq 'GET') {
        my $user_data_json = $self->getUserData($username, $session_id);
        return $user_data_json;
    }
    elsif ($formMethod eq 'POST') {
        my $user_groups = $q->param('groups');
        my $status_json = $self->saveUserData($username, $user_groups);
        return $status_json;
    }
    else {
        my $status = { error => "contact database administrator" };
        return encode_json($status);
    }
}


# Helper methods
sub getUserData {
    my ($self, $username, $CGISESSID) = @_;

    my $shiny_data = {
        user => $username,
        'CGISESSID' => $CGISESSID,
    };

    unless($username) {
        return $self->returnError($shiny_data, 'User not logged in') 
    }
    
    # DB Accessor object
    my $fdg = Modules::FormDataGenerator->new();
    $fdg->dbixSchema($self->dbixSchema);

    # Location Manager object for parsing geocoded addresses
    my $lm = Modules::LocationManager->new();
    $lm->dbixSchema($self->dbixSchema);

    # Get genome data
    my $public_meta = $fdg->_runGenomeQuery(1,$username);
    my $private_meta = $fdg->_runGenomeQuery(0,$username);

    # Initialize variables
    my @ordered_genomes;
    my %genome_ids;
    my $i = 0;
    map { $genome_ids{$_} = $i; $i++; push @ordered_genomes, $_; } sort keys %{$public_meta};
    map { $genome_ids{$_} = $i; $i++; push @ordered_genomes, $_; } sort keys %{$private_meta};

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
            # allowing groups in different categories to have same name. Currently
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
                # Only encode custom groups
                my $group_name = $group_hashref->{$group_id};
                $group_lists->{$group_name}->[$index] = 1 if $group_name;
            }
        }
    }

    map { $shiny_data->{'data'}{$_} = $meta_categories->{$_} } keys %$meta_categories;
    map { $shiny_data->{'data'}{$_} = $extra_date_categories->{$_} } keys %$extra_date_categories;
    map { $shiny_data->{'data'}{$_} = $extra_location_categories->{$_} } keys %$extra_location_categories;
    map { $shiny_data->{'groups'}{$_} = $group_lists->{$_} } keys %$group_lists;
    $shiny_data->{'status'} = "User data retrieved for $username";
    $shiny_data->{'genomes'} = \@ordered_genomes;

    return $self->returnJSON($shiny_data);
}

sub returnError {
    my $self = shift;
    my $shiny_data = shift;
    my $msg = shift;

    $shiny_data->{error} = $msg;

    # Set response header type
    $self->header_add('-type' => 'application/json');

    return encode_json($shiny_data)
}

sub returnJSON {
    my $self = shift;
    my $shiny_data = shift;
    
    # Set response header type
    $self->header_add('-type' => 'application/json');

    return encode_json($shiny_data)
}

sub saveUserData {
    my ($self, $username, $group_json) = @_;

    my $response = {
        user => $username
    };

    unless($username) {
        return $self->returnError($response, 'User not logged in') 
    }
   
    my $shiny_data = decode_json($group_json);
    my $ordered_genomes = $shiny_data->{genomes};
    my $shiny_groups = $shiny_data->{groups};
    unless($ordered_genomes) {
        return $self->returnError($response, "JSON Error! Missing 'genomes' object.");
    }
    unless($shiny_groups) {
        return $self->returnError($response, "JSON Error! Missing 'groups' object.");
    }

    my $data = Modules::FormDataGenerator->new(dbixSchema => $self->dbixSchema, 
        cvmemory => $self->cvmemory);

    # Iterate through groups
    # Identify new, modified and deleted groups

    # Rollback on failure
    my $guard = $self->dbixSchema->txn_scope_guard;
    
    my $group_rs = $self->dbixSchema->resultset('GenomeGroup')->search(
        { 
            username => $username
        },
        {
            columns => [name genome_group_id]
        }
    );

    my %modified;
    while(my $group_row = $group_rs->next) {
        if($shiny_groups->{$group_row->name}) {
            # Group also in Shiny set, perform update
            # Update group members
            # Note: the group properties are currently not accessible in Shiny, so
            # only the group members need to be updated

            my $i = 0;
            my @genomes;
            foreach my $value (@{$shiny_groups->{$group_row->name}}) {
                if($value) {
                    push @genomes, $ordered_genomes->[$i];
                }
            }

            # Validate genomes
            my $warden = Modules::GenomeWarden->new(schema => $self->dbixSchema, 
                genomes => \@genomes, user => $username, 
                cvmemory => $self->cvmemory);

            my ($err, $bad1, $bad2) = $warden->error; 
            if($err) {
                # User requested invalid strains or strains that they do not have permission to view
                return $self->returnError($response, 'Access Violation Error! User does not have access to uploaded genomes: '.join(', ',@$bad1, @$bad2));
            }

            # Update group members
            my $rs = $data->updateGroupMembers($warden, {
                group_id => $group_row->genome_group_id,
                username => $username
            });

            unless($rs) {
                return $self->returnError($response, "Internal Error! Update of group ".$group_row->name." failed.");
            }

        }

        $modified{$group_row->name} = 1;
    }

    # Create new groups
    foreach my $group_name (keys %{$shiny_groups}) {
        unless($modified{$group_name}) {
            # New group not seen before

            my $i = 0;
            my @genomes;
            foreach my $value (@{$shiny_groups->{$group_name}}) {
                if($value) {
                    push @genomes, $ordered_genomes->[$i];
                }
            }

            # Validate genomes
            my $warden = Modules::GenomeWarden->new(schema => $self->dbixSchema, 
                genomes => \@genomes, user => $username, 
                cvmemory => $self->cvmemory);

            my ($err, $bad1, $bad2) = $warden->error; 
            if($err) {
                # User requested invalid strains or strains that they do not have permission to view
                return $self->returnError($response, 'Access Violation Error! User does not have access to uploaded genomes: '.join(', ',@$bad1, @$bad2));
            }

            # Create group
            my $rs = $data->createGroup($warden, {
                name => $group_name,
                username => $username
            });

            unless($rs) {
                return $self->returnError($response, "Internal Error! Creation of group ".$group_name." failed.");
            }
        }
    }

    # Save all changes
    $guard->commit;


    $response->{status} = "User data updated";
    return $self->returnJSON($response);
}

1;