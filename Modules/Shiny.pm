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
    #TODO: Pass in a CGI key as a parameter and get user specific data
    my $self = shift;

    my $q = $self->query();

    my $SHINYSESSID = $q->param('CGISESSID');

    my $CGISESSID = $self->session->id();

    #print STDERR "Session key returned from shiny is: $SHINYSESSID\n";

    #print STDERR "Current CGI key is $CGISESSID\n";
    
    my $fdg = Modules::FormDataGenerator->new();
    $fdg->dbixSchema($self->dbixSchema);
    
    my $username = $self->authen->username;
    print STDERR "User logged in is: $username\n" if $username;
    print STDERR "No user currently logged in\n" unless $username;

    my ($pub_json, $pvt_json) = $fdg->genomeInfo($username);

    # Phylogenetic tree
    my $tree = Phylogeny::Tree->new(dbix_schema => $self->dbixSchema);
    my $tree_string;
    # find visable nodes for user
    my $visable_nodes;
    $fdg->publicGenomes($visable_nodes);
    my $has_private = $fdg->privateGenomes($username, $visable_nodes);
    
    if($has_private) {
        $tree_string = $tree->fullTree($visable_nodes);
    } 
    else {
        $tree_string = $tree->fullTree();
    }

    my $public_genome_objs = decode_json($pub_json);
    my $private_genome_objs = decode_json($pvt_json);

    #Generate sorted public genome ids
    my @sorted_public_genomes = sort {$a cmp $b} (keys %$public_genome_objs);

    #Generate sorted private genoem ids
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

    my $shiny_data = {
        'user' => $username // undef,
        'cgissessionid' => $CGISESSID,
        'data' => {'genome_id' => \@sorted_genome_ids}
    };

    @{$shiny_data->{'data'}}{keys %$meta_categories} = values %$meta_categories;
    @{$shiny_data->{'data'}}{keys %$extra_date_categories} = values %$extra_date_categories;
    @{$shiny_data->{'data'}}{keys %$extra_location_categories} = values %$extra_location_categories;

    #my $data = {
    #   'public_genomes' => decode_json($pub_json),
    #   'private_genomes' => decode_json($pvt_json),
    #   'tree' => $tree_string
    #};
    #return encode_json($data);

    return encode_json($shiny_data);
}

sub groups : Runmode {
    # TODO: Save JSON of groups
    my $self = shift;
    return;
}

sub test : StartRunmode {
    my $self = shift;
    my $template = $self->load_tmpl('shiny_test.tmpl', die_on_bad_params => 0);
    my $CGISESSID = $self->session->id();
    #print STDERR "New session key is: $CGISESSID\n";
    $template->param(CGISESSID => $CGISESSID);
    return $template->output();
}

1;