#!/usr/bin/env perl


package Modules::Groups;

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

=head2 setup

Defines the start and run modes for CGI::Application and connects to the database.

=cut

sub setup {
    my $self=shift;
    my $logger = Log::Log4perl->get_logger();
    $logger->info("Logger initialized in Modules::Groups");
}

sub search : StartRunmode {
    my $self = shift;

    my $fdg = Modules::FormDataGenerator->new();
    $fdg->dbixSchema($self->dbixSchema);
    
    my $username = $self->authen->username;
    my ($pub_json, $pvt_json) = $fdg->genomeInfo($username);

    my $template = $self->load_tmpl('groups_search.tmpl', die_on_bad_params => 0);

    $template->param(public_genomes => $pub_json);
    $template->param(private_genomes => $pvt_json) if $pvt_json;
    
    # Phylogenetic tree
    my $tree = Phylogeny::Tree->new(dbix_schema => $self->dbixSchema);
    
    # find visable nodes for user
    my $visable_nodes;
    $fdg->publicGenomes($visable_nodes);
    my $has_private = $fdg->privateGenomes($username, $visable_nodes);
    
    if($has_private) {
        my $tree_string = $tree->fullTree($visable_nodes);
        $template->param(tree_json => $tree_string);
        } else {
            my $tree_string = $tree->fullTree();
            $template->param(tree_json => $tree_string);
        }

    # Groups Manager, only active if user logged in
    $template->param(groups_manager => 0) unless $username;
    $template->param(groups_manager => 1) if $username;

    $template->param(title1 => 'GROUP');
    $template->param(title2 => 'SEARCH');

    return $template->output();
}

# Group Form Functions
sub save : Runmode {
    my $self = shift;
    my $q = $self->query();

    my %status;
    
    my $option = $q->param('group-manager-option');
    my $groupName = $q->param('group-name');
    my $groupNumber = $q-> param('group-number');
    my $maxGroups = $q->param('max-groups');

    print STDERR $groupName . "\n";
    print STDERR $groupNumber . "\n";

    if ($option eq 'new-group') {
        if (!$groupName) {
            $status{'error'} = "You must enter a group name to create a new group"; 
        }
        elsif (!$groupNumber) {
            $status{'error'} = "You must specify which group number to save";
        }
        elsif ($groupNumber > $maxGroups) {
            $status{'error'} = "Group $groupNumber is not valid";
        }
        else {
            # TODO
            $status{'success'} = "Your group has been saved successfully";
        }
    }

    return encode_json(\%status);
}

sub load : Runmode {
    # TODO:
    my $self = shift;
    return;
}
sub delete : Runmode {
    # TODO:
    my $self = shift;
    return;
}

sub _update {
    # TODO:
    return;
}

sub _rename {
    # TODO
    return;
}

1;