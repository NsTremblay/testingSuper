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
    my $logger = Log::Log4perl->get_logger();
    $logger->info("Logger initialized in Modules::Shiny");
}

sub data : Runmode {
    #TODO: Check all security constraints and make sure this is air tight
    my $self = shift;

    my $q = $self->query();

    #my $SHINYSESSID = $q->param('CGISESSID');
    #my $SHINYURI = $q->param('uri');
    #my $SHINYUSER = $q->param('user');

    my $CGISESSID = $self->session->id();

    #print STDERR "Shiny returned CGISESSID: " . $SHINYSESSID . "\n";
    print STDERR "Current CGISESSID: " . $CGISESSID . "\n";

    my $formMethod = $ENV{'REQUEST_METHOD'};

    # Check user is logged in
    my $username = $self->authen->username;

    print STDERR "User logged in is: $username\n" if $username;
    print STDERR "No user currently logged in\n" unless $username;

    if ($formMethod eq 'GET') {
        print STDERR "\nGET method called\n\n";
        my $user_data_json = $self->_getUserData($username, $CGISESSID);
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

    my $fdg = Modules::FormDataGenerator->new();
    $fdg->dbixSchema($self->dbixSchema);

    my $status = {};

    my ($pub_json, $pvt_json) = $fdg->genomeInfo($username);

    # # Phylogenetic tree
    # my $tree = Phylogeny::Tree->new(dbix_schema => $self->dbixSchema);
    # my $tree_string;
    # # find visable nodes for user
    # my $visable_nodes;
    # $fdg->publicGenomes($visable_nodes);
    # my $has_private = $fdg->privateGenomes($username, $visable_nodes);
    
    # if($has_private) {
    #     $tree_string = $tree->fullTree($visable_nodes);
    # } 
    # else {
    #     $tree_string = $tree->fullTree();
    # }

    my $public_genome_objs = decode_json($pub_json);
    my $private_genome_objs = decode_json($pvt_json);

    #Generate sorted public genome ids
    my @sorted_public_genomes = sort {$a cmp $b} (keys %$public_genome_objs);

    #Generate sorted private genome ids
    my @sorted_private_genomes = sort {$a cmp $b} (keys %$private_genome_objs);

    # Genome ids to be sent back to shiny for group creation
    my @sorted_genome_ids = (@sorted_public_genomes, @sorted_private_genomes);

    my $meta_categories = {
        'primary_dbxref' => [],
        'strain' => [],
        'serotype' => [],
        'isolation_host' => [],
        'isolation_source' => [],
        'isolation_date' => [],
        'syndrome' => [],
        'stx1_subtype' => [],
        'stx2_subtype' => [],
        'isolation_location' => []
    };

    my $extra_date_categories = {
        'isolation_year' => [],
        'isolation_month' => [],
        'isolation_day' => [],
    };

    my $extra_location_categories = {
        'isolation_country' => [],
        'isolation_province_state' => [],
        'isolation_city' => []
    };

    # Location Manager object for parsing geocoded addresses
    my $lm = Modules::LocationManager->new();
    $lm->dbixSchema($self->dbixSchema);

    foreach my $genome_id (@sorted_genome_ids) {
        my $genome_obj;
        if($private_genome_objs->{$genome_id}) {
            $genome_obj = $private_genome_objs->{$genome_id};
        }
        else {
            $genome_obj = $public_genome_objs->{$genome_id};
        }
        foreach my $meta_cat (keys %$meta_categories) {
            switch ($meta_cat) {
                case 'isolation_date' {
                    unless ($genome_obj->{$meta_cat}) {
                        push($meta_categories->{$meta_cat}, undef);
                        push($extra_date_categories->{"$_"}, undef) foreach (keys %$extra_date_categories);
                    }
                    else {
                        #Format the date
                        push($meta_categories->{$meta_cat}, join('', @{$genome_obj->{$meta_cat}}));
                        my @date = split('-', join('', @{$genome_obj->{$meta_cat}}));
                        push($extra_date_categories->{'isolation_year'}, $date[0]);
                        push($extra_date_categories->{'isolation_month'}, $date[1]);
                        push($extra_date_categories->{'isolation_day'}, $date[2]);
                    }
                }
                case 'isolation_location' {
                    unless ($genome_obj->{$meta_cat}) {
                        push($meta_categories->{$meta_cat}, undef);
                        push($extra_location_categories->{"$_"}, undef) foreach (keys %$extra_location_categories);
                    }
                    else {
                        #Format the location
                        my $location_ref = decode_json($genome_obj->{$meta_cat}->[0]);
                        push($meta_categories->{$meta_cat}, $location_ref->{'formatted_address'});
                        my $parsed_location_ref = $lm->parseGeocodedAddress($location_ref);
                        foreach (keys %$extra_location_categories) {
                            push($extra_location_categories->{"$_"}, $parsed_location_ref->{"$_"}) if $parsed_location_ref->{"$_"};
                            push($extra_location_categories->{"$_"}, undef) unless $parsed_location_ref->{"$_"};
                        }
                    }
                }
                else {
                    unless ($genome_obj->{$meta_cat}) {
                        push($meta_categories->{$meta_cat}, undef); 
                    }
                    else {
                        push($meta_categories->{$meta_cat}, $genome_obj->{$meta_cat}) unless ref($genome_obj->{$meta_cat}) eq "ARRAY";
                        push($meta_categories->{$meta_cat}, join(' ', @{$genome_obj->{$meta_cat}})) if ref($genome_obj->{$meta_cat}) eq "ARRAY";
                    }
                }
            }
        }
    }

    $status->{error} = "User is not logged in" unless $username;
    $status->{status} = "User data retrieved for $username" if $username;

    my $userGroupQuery = $self->dbixSchema->resultset('UserGroup')->find({username => $username});

    my $userGroups = $userGroupQuery->user_groups if $userGroupQuery // undef;

    my $user_groups_obj = decode_json($userGroups) if $userGroupQuery;
    $user_groups_obj = {} unless $userGroupQuery;

    #print STDERR "$_\n" foreach (keys %$user_groups_obj);

    my $shiny_data = {
        'user' => $username // undef,
        'CGISESSID' => $CGISESSID,
        'data' => {},
        'genome_id' => \@sorted_genome_ids,
    };

    @{$shiny_data->{'data'}}{keys %$meta_categories} = values %$meta_categories;
    @{$shiny_data->{'data'}}{keys %$extra_date_categories} = values %$extra_date_categories;
    @{$shiny_data->{'data'}}{keys %$extra_location_categories} = values %$extra_location_categories;
    $shiny_data->{'groups'} = $user_groups_obj;
    $shiny_data->{'status'} = $status;

    #%$shiny_data = (%$shiny_data, %$user_groups_obj);

    # This data is for the map and tree, which is not currently being used in shiny
    #my $data = {
    #   'public_genomes' => decode_json($pub_json),
    #   'private_genomes' => decode_json($pvt_json),
    #   'tree' => $tree_string
    #};
    #return encode_json($data);

    #TODO: Get user groups and add them in

    return encode_json($shiny_data);
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