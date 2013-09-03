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
use IO::File;
use Log::Log4perl qw'get_logger';

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
	
	
	#my $formDataRef = $formDataGenerator->getFormData();
	#my ($pubDataRef, $priDataRef , $strainJsonDataRef) = $formDataGenerator->getFormData();
	
	my $template = $self->load_tmpl( 'group_wise_comparison.tmpl' , die_on_bad_params=>0 );
	
	#$template->param(FEATURES=>$pubDataRef);
	#$template->param(strainJSONData=>$strainJsonDataRef);
	
	$template->param(public_genomes => $pub_json);
	$template->param(private_genomes => $pvt_json) if $pvt_json;
	
	my $tree = Phylogeny::Tree->new(dbix_schema => $self->dbixSchema);
	$template->param(tree_json => $tree->fullTree());
	
	if($errs) {
		$template->param(comparison_failed => $errs);
	}
	
	
	return $template->output();
}

sub group_wise_info : Runmode {

	my $self=shift;
	my $formDataGenerator = Modules::FormDataGenerator->new();
	my $q = $self->query();
	my @groupOneStrainNames = $q->param("group1");
	my @groupTwoStrainNames = $q->param("group2");

	if(!(@groupOneStrainNames) && !(@groupTwoStrainNames)){
		return $formDataGenerator->_getJSONFormat("");
	}
	else{
		my ($groupOneBinaryDataRef , $groupOneSnpDataRef) = $self->_getStrainInfo(\@groupOneStrainNames);
		my ($groupTwoBinaryDataRef , $groupTwoSnpDataRef) = $self->_getStrainInfo(\@groupTwoStrainNames);
		my @phyloList = (@groupOneStrainNames, @groupTwoStrainNames);

		#Append "public_to all the items in phylo list so the labels can be identified in the tree"
		foreach my $phyloLabel (@phyloList) {
			$phyloLabel = "public_" . $phyloLabel;
		}

		my $groupWiseTreeRef = $self->_getGroupWisePhylo(\@phyloList);
		my @arr;
		push (@arr, $groupOneBinaryDataRef, $groupOneSnpDataRef, $groupTwoBinaryDataRef, $groupTwoSnpDataRef, $groupWiseTreeRef);
		my $groupWiseDataJSONref = $formDataGenerator->_getJSONFormat(\@arr);
		return $groupWiseDataJSONref;
	}
}

sub comparison : Runmode {
	my $self = shift;
	
	my $q = $self->query();
	my @group1 = $q->param("comparison-group1-genome");
	my @group2 = $q->param("comparison-group2-genome");

	if(!@group1 && !@group2){
		return $self->group_wise_comparisons('one or more groups were empty');
	} else {
		my $template = $self->load_tmpl( 'comparison.tmpl' , die_on_bad_params=>0 );
		#Need to return the data from the group comparator module
		my $binaryDataRef = $self->_getStrainInfo(\@group1);
		return $template->output();
	} 
}


=head2 _getStrainInfo

Writes out user selected fasta files for PanSeq analysis.

=cut

sub _getStrainInfo {
	my $self = shift;
	my $_groupedStrainNames = shift;

	#push (my @strainNames , @{$_groupedStrainNames}); 

	#my $ffwHandle = Modules::FastaFileWrite->new();
	#$ffwHandle->dbixSchema($self->dbixSchema);
	#$ffwHandle->writeStrainsToFile($_groupedStrainNames);

	my $formDataGenerator = Modules::FormDataGenerator->new();
	$formDataGenerator->dbixSchema($self->dbixSchema);
	my $formDataRef = $formDataGenerator->getFormData();

	my $comparisonHandle = Modules::GroupComparator->new();
	$comparisonHandle->dbixSchema($self->dbixSchema);
	my $binaryDataRef = $comparisonHandle->getBinaryData($_groupedStrainNames);
	#my $snpDataRef = $comparisonHandle->getSnpData($_groupedStrainNames);

	#return ($binaryDataRef , $snpDataRef);
	return $binaryDataRef;
}

sub _getGroupWisePhylo {
	my $self = shift;
	my $_phyloList = shift;
	my $groupWiseTreeRef;

	#Create a new instance of tree manipulator and call the _getNearestClades function
	my $groupWiseTreeMaker = Modules::TreeManipulator->new();
	$groupWiseTreeMaker->inputDirectory("../../Phylogeny/NewickTrees/");
	$groupWiseTreeMaker->newickFile("example_tree");
	$groupWiseTreeMaker->_pruneTree($_phyloList);
	my $groupWiseTreeFile = $groupWiseTreeMaker->outputDirectory() . $groupWiseTreeMaker->outputTree();
	open my $in, '<' , $groupWiseTreeFile or die "Cant write to the $groupWiseTreeFile: $!";
	while (<$in>) {
		$groupWiseTreeRef .= $_;
	}
	my $systemLine = 'rm -r ' . $groupWiseTreeFile;
	system($systemLine);

	return $groupWiseTreeRef;
}

1;