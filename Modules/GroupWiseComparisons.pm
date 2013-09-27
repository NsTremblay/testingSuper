#!/usr/bin/env perl

=pod

=head1 NAME

Modules::GroupWiseComparisons

=head1 SNYNOPSIS

=head1 DESCRIPTION

=head1 ACKNOWLEDGMENTS

Thank you to Dr. Chad Laing and Dr. Michael Whiteside, for all their assistance on this project

=head1 COPYRIGHT

This work is released under the GNU General Public License v3  http://www.gnu.org/licenses/gpl.htm

=head1 AVAILABILITY

The most recent version of the code may be found at:

=head1 AUTHOR

Akiff Manji (akiff.manji@gmail.com)

=head1 Methods

=cut

package Modules::GroupWiseComparisons;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use parent 'Modules::App_Super';
use Modules::FormDataGenerator;
use Modules::FastaFileWrite;
use HTML::Template::HashWrapper;
use CGI::Application::Plugin::AutoRunmode;;
use Phylogeny::Tree;
use Modules::GroupComparator;
use Modules::TreeManipulator;
use Data::FormValidator::Constraints (qw/valid_email/);
use Log::Log4perl qw'get_logger';
use Time::HiRes;
use Math::Round 'nlowmult';
use IO::File;
use File::Temp;
use Proc::Daemon; #To fork off long processes

sub setup {
	my $self=shift;
	
	get_logger()->info("Logger initialized in Modules::GroupWiseComparisons");
}

=head2 groupWiseComparisons

Run mode for the group wise comparisons page

=cut

sub group_wise_comparisons : StartRunmode {
	my $self = shift;
	my $errs = shift;
	
	my $formDataGenerator = Modules::FormDataGenerator->new();
	$formDataGenerator->dbixSchema($self->dbixSchema);
	
	my $username = $self->authen->username;
	
	# Retrieve form data
	my ($pub_json, $pvt_json) = $formDataGenerator->genomeInfo($username);
	
	my $template = $self->load_tmpl( 'group_wise_comparison.tmpl' , die_on_bad_params=>0 );
	
	$template->param(groupwise => 1);
	$template->param(public_genomes => $pub_json);
	$template->param(private_genomes => $pvt_json) if $pvt_json;
	
	my $tree = Phylogeny::Tree->new(dbix_schema => $self->dbixSchema);
	$template->param(tree_json => $tree->fullTree());
	
	if($errs) {
		$template->param(comparison_failed => $errs);
	}
	
	return $template->output();
}

sub comparison : Runmode {
	my $start = Time::HiRes::gettimeofday();
	my $self = shift;
	
	my $q = $self->query();
	my @group1 = $q->param("comparison-group1-genome");
	my @group2 = $q->param("comparison-group2-genome");
	my @group1Names = $q->param("comparison-group1-name");
	my @group2Names = $q->param("comparison-group2-name");

	my $email = $q->param("email-results");

	if(!@group1 && !@group2){
		return $self->group_wise_comparisons('one or more groups were empty');
	}
	elsif ($email) {
		my $user_email = $q->param("user-email");
		my $user_email_confirmed = $q->param("user-email-confirmed");
		if (($user_email eq $user_email_confirmed) && (valid_email($user_email))) {
			$self->_emailStrainInfo($user_email, \@group1 , \@group2 , \@group1Names , \@group2Names);
		}
		else {
			return $self->group_wise_comparisons('invalid email address was entered');
		}
	}
	else {
		my $template = $self->load_tmpl( 'comparison.tmpl' , die_on_bad_params=>0 );
		my ($binaryFETResults, $snpFETResults) = $self->_getStrainInfo(\@group1 , \@group2 , \@group1Names , \@group2Names);
		my $end = Time::HiRes::gettimeofday();
		my $run_time = nlowmult(0.01, $end - $start);
		$template->param(binaryFETResults => $binaryFETResults);
		$template->param(snpFETResults => $snpFETResults);
		$template->param(run_time => $run_time);
		return $template->output();
	}
}

=head2 _getStrainInfo

=cut

sub _getStrainInfo {
	my $self = shift;
	my $_group1StrainIds = shift;
	my $_group2StrainIds = shift;
	my $_group1StrainNames = shift;
	my $_group2StrainNames = shift;
	my $comparisonHandle = Modules::GroupComparator->new();
	$comparisonHandle->dbixSchema($self->dbixSchema);
	my $_binaryFETResults = $comparisonHandle->getBinaryData($_group1StrainIds, $_group2StrainIds, $_group1StrainNames , $_group2StrainNames);
	my $_snpFETResults = $comparisonHandle->getSnpData($_group1StrainIds, $_group2StrainIds, $_group1StrainNames , $_group2StrainNames);
	return ($_binaryFETResults, $_snpFETResults);
}

sub _emailStrainInfo {

	#This method needs to be changed.
	my $self = shift;
	my $_user_email = shift;
	my $_group1StrainIds = shift;
	my $_group2StrainIds = shift;
	my $_group1StrainNames = shift;
	my $_group2StrainNames = shift;

	#Need to write all the params needed to send the email
	# #---User Email---

	# [user]
	# email = ;
	# gp1IDs = ;
	# gp2IDs = ;
	# gp1Names = ;
	# gp2Names =;
	
	my $userConFile = File::Temp->new(	TEMPLATE => 'user_conf_tempXXXXXXXXXX',
		DIR => '/home/genodo/group_wise_data_temp/',
		UNLINK => 0);

	my $userConString = "#---User Email---\n\n";
	$userConString .= '[user]' . "\n";
	$userConString .= "email = $_user_email\n";
	$userConString .= "gp1IDs = " . join(',' , @{$_group1StrainIds}) . "\n";
	$userConString .= "gp2IDs = " . join(',' , @{$_group2StrainIds}) . "\n";
	$userConString .= "gp1Names = " . join(',', @{$_group1StrainNames}) . "\n";
	$userConString .= "gp2Names = " . join(',', @{$_group2StrainNames});

	print $userConFile $userConString or die "$!";

	# Fork program and run loading separately
	my $cmd = "perl $FindBin::Bin/../../Data/email_user_data.pl --config $FindBin::Bin/../../Modules/genodo.cfg --user_config $userConFile";
	my $daemon = Proc::Daemon->new(
		work_dir => "$FindBin::Bin/../../Data/",
		exec_command => $cmd,
		child_STDERR => "/home/genodo/logs/group_wise_comparisons.log"
		);
	#Fork
	$self->session->close;
	my $kid_pid = $daemon->Init;

	#Return Parent
	my $template = $self->load_tmpl( 'comparison_email.tmpl' , die_on_bad_params=>0 );
	return $template->output();
	
	# $self->session->close;
	# my $template = $self->load_tmpl( 'comparison_email.tmpl' , die_on_bad_params=>0 );
	# my $pid = fork;
	# if ($pid) {
	# 	$template->param(email_address=>$_user_email);
	# 	return $template->output();
	# 	waitpid $pid, 0;
	# }
	# else {
	# 	close STDIN;
	# 	close STDOUT;
	# 	close STDERR;
	# 	my $comparisonHandle = Modules::GroupComparator->new();
	# 	$comparisonHandle->dbixSchema($self->dbixSchema);
	# 	$comparisonHandle->configLocation($self->config_file);
	# 	$comparisonHandle->emailResultsToUser($_user_email, $_group1StrainIds, $_group2StrainIds, $_group1StrainNames , $_group2StrainNames);
	# }
}

1;