#!/usr/bin/perl

=pod

=head1 NAME

Modules::StrainInfo

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

package Modules::StrainInfo;

use strict;
use warnings;
use FindBin;
use lib 'FindBin::Bin/../';
use parent 'Modules::App_Super';
use CGI::Application::Plugin::AutoRunmode;

=head2 setup

Defines the start and run modes for CGI::Application and connects to the database.

=cut

sub setup {
	my $self=shift;
	my $logger = Log::Log4perl->get_logger();
	$logger->info("Logger initialized in Modules::StrainInfo");
	
}

=head2 strain_info

Run mode for the sinle strain page

=cut

sub strain_info : StartRunmode {
	my $self = shift;
	
	my ($pubDataRef, $priDataRef) = $self->getGenomes();
	
#	my $logger = Log::Log4perl->get_logger();
#	$logger->debug('USER: '.$self->authen->username);
#	foreach(@$priDataRef) {
#		$logger->debug('USERs PRIVATE GENOME ID: '.$_);
#	}

my $template = $self->load_tmpl( 'strain_info.tmpl' , die_on_bad_params=>0 );

my $q = $self->query();
my $strainID = $q->param("singleStrainID");
my $privateStrainID = $q->param("privateSingleStrainID");

	# Populate forms
	$template->param(FEATURES => $pubDataRef);
	if(@$priDataRef) {
		# User has private data
		$template->param(PRIVATE_DATA => 1);
		$template->param(PRIVATE_FEATURES => $priDataRef);
		
		} else {
			$template->param(PRIVATE_DATA => 0);
		}

		if(defined $strainID && $strainID ne "") {
		# User requested information on public strain
		
		my $strainInfoDataRef = $self->_getStrainInfo($strainID, 1);
		$template->param(METADATA=>$strainInfoDataRef);
		
		my $validator = "Return Success";
		$template->param(VALIDATOR=>$validator);
		
		} elsif(defined $privateStrainID && $privateStrainID ne "") {
		# User requested information on private strain
		
		# Verify that user has access to strain
		my $confirm_access=0;
		foreach my $str (@$priDataRef) {
			if($privateStrainID eq $str->{feature_id}) {
				$confirm_access = 1;
				last;
			}
		}
		
		unless($confirm_access) {
			# User requested strain that they do not have permission to view
			$self->session->param( status => '<strong>Permission Denied!</strong> You have not been granted access to uploaded genome ID: '.$privateStrainID );
			return $self->redirect( $self->home_page );
		}
		
		# Obtain private strain info
		my $strainInfoDataRef = $self->_getStrainInfo($privateStrainID, 0);
		$template->param(METADATA => $strainInfoDataRef);
		
		my $validator = "Return Success";
		$template->param(VALIDATOR => $validator);
	}
	
	return $template->output();
}


=head2 _getStrainInfo

Takes in a strain name paramer and queries it against the appropriate table.
Returns an array reference to the strain metainfo.

=cut

sub _getStrainInfo {
	my $self = shift;
	my $strainID = shift;
	my $public = shift;

	my @strainMetaData;
	
	my $feature_table_name = 'Feature';
	my $featureprop_table_name = 'Featureprop';
	
	# Data is in private tables
	unless($public) {
		$feature_table_name = 'PrivateFeature';
		$featureprop_table_name = 'PrivateFeatureprop';
	}

	my $features = $self->dbixSchema->resultset($feature_table_name)->search({ feature_id => $strainID});
	my $featureprops = $self->dbixSchema->resultset($featureprop_table_name)->search({ feature_id => $strainID});

	## GRAB DATA -- this just a demo. Need to obtain all required strain metadata ###
	#Akiff: I will add a sub here to get a list of the virulence factrs and AMR genes
	
	while(my $row = $featureprops->next) {
		my %strainRowData;
		$strainRowData{'FEATUREID'} = $strainID;
		$strainRowData{'VALUE'} = $row->value;
		$strainRowData{'TYPEID'} = $row->type_id;
		push(@strainMetaData, \%strainRowData);
	}
	return \@strainMetaData;
}

sub _getVirulenceData {
	my $self = shift;
	my $strainID = shift;
	my $virulence_table_name = 'RawVirulenceData';

	my @virulenceData;
	my $virCount = 0;

	my $virulenceData = $self->dbixSchema->resultset($virulence_table_name)->search(
		{'me.strain' => "$strainID"},
		{
			column => [qw/me.strain me.gene_name me.presence_absence/]
		}
		);

	while (my $virulenceDataRow = $virulenceData->next) {
		if ($virulenceDataRow->presence_absence == 1) {
		}
		else {
		}
	}
	return \@virulenceData;
}

sub _getAmrData {
	my $self = shift;
	my $strainID = shift;
	my $amr_table_name = 'RawAmrData';

	my @amrData;
	my $amrCount = 0;

	my $amrData = $self->dbixSchema->resultset($amr_table_name)->search(
		{'me.strain' => "$strainID"},
		{
			column => [qw/me.strain me.gene_name me.presence_absence/]
		}
		);

	while (my $amrDataRow = $amrData->next) {
		if ($amrDataRow->presence_absence == 1) {
		}
		else {
		}
	}
	return \@amrData;
}

1;
