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
use parent 'CGI::Application';
use Modules::FormDataGenerator;

=head2 setup

Defines the start and run modes for CGI::Application and connects to the database.
Run modes are passed in as <reference name>=><subroutine name>

=cut

sub setup {
	my $self=shift;
	$self->logger(Log::Log4perl->get_logger());
	$self->logger->info("Logger initialized in Modules::StrainInfo");
	$self->start_mode('default');
	$self->run_modes(
		'default'=>'default',
		'strain_info'=>'strainInfo'
		);

	$self->connectDatabase({
		'dbi'=>'Pg',
		'dbName'=>'chado_db_test',
		'dbHost'=>'localhost',
		'dbPort'=>'5432',
		'dbUser'=>'postgres',
		'dbPass'=>'postgres'
		});
}

=head2 default

Default start mode. Must be decalared or CGI:Application will die. 

=cut

sub default {
	my $self = shift;
	my $template = $self->load_tmpl ( 'hello.tmpl' , die_on_bad_params=>0 );
	return $template->output();
}

=head2 singleStrainInfo

Run mode for the sinle strain page

=cut

sub strainInfo {
	my $self = shift;
	my $formDataGenerator = Modules::FormDataGenerator->new();
	$formDataGenerator->dbixSchema($self->dbixSchema);
	my $formDataRef = $formDataGenerator->getFormData();
	my $template = $self->load_tmpl( 'strain_info.tmpl' , die_on_bad_params=>0 );

	my $q = $self->query();
	my $strainName = $q->param("singleStrainName");

	if(!defined $strainName || $strainName eq ""){
		$template->param(FEATURES=>$formDataRef);
	}
	else {
		my $strainInfoDataRef = $self->_getStrainInfo($strainName);
		$template->param(FEATURES=>$formDataRef);
		$template->param(METADATA=>$strainInfoDataRef);
		my $validator = "Return Success";
		$template->param(VALIDATOR=>$validator);
	}
	return $template->output();
}

=head2 _getStrainInfo

Takes in a strain name paramer and queries it against the database.
Returns an array reference to the strain metainfo.

=cut

sub _getStrainInfo {
	my $self = shift;
	my $_strainName = shift;
	my @strainMetaData;

	my $strainFeaturepropTable = $self->dbixSchema->resultset('Featureprop');
	my $strainFeatureTable = $self->dbixSchema->resultset('Feature');

	my $_featureProps = $strainFeaturepropTable->search(
		{value => "$_strainName"},
		{
			column => [qw/me.feature_id/],
			order_by => {-asc => ['me.feature_id']}
		}
		);

	while (my $_featurepropsRow = $_featureProps->next) {
		my %strainRowData;
		$strainRowData{'FEATUREID'}=$_featurepropsRow->feature_id;
		push(@strainMetaData, \%strainRowData);
	}
	return \@strainMetaData;
}

1;
