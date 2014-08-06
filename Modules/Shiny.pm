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
use Modules::TreeManipulator;
use Modules::LocationManager;
use JSON;
use Time::HiRes;

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

    my $data = {
        'public_genomes' => decode_json($pub_json),
        'private_genomes' => decode_json($pvt_json),
        'tree' => $tree_string
    };
    return encode_json($data);

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