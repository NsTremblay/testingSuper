package Module::Home;

#!/usr/bin/perl

=pod

=head1 NAME

Module::Home - A Class that provides the following functionality:

=head1 SYNOPSIS


	use Example::Module::ClassTemplate;
	
	my $obj = Example::Module::ClassTemplate->new(
		'param1'=>'setting1',
		'param2'=>'setting2'
	);
	$obj->method1;
	$obj->method2;

=head1 DESCRIPTION

This module is explained here.

=cut

=head1 ACKNOWLEDGEMENTS

Thanks.

=head1 COPYRIGHT

This work is released under the GNU General Public License v3  http://www.gnu.org/licenses/gpl.html

=head1 AVAILABILITY

The most recent version of the code may be found at: 
https://bitbucket.org/chadlaing/computational_platform/src

=head1 AUTHOR

Akiff Manji (akiff.manji@gmail.com)

=head2 Methods

=cut

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Log::Log4perl;
use Carp; #this enables a stack trace unlike warn/die
use parent 'Modules::App_Super';
use parent 'CGI::Application';
use Role::Tiny::With;
#use Plyogeny::PhyloTreeBuilder;
with 'Roles::DatabaseConnector';

# #object creation
# sub new {
# 	my ($class) = shift;
# 	my $self = {};
# 	bless( $self, $class );
# 	$self->_initialize(@_);
# 	return $self;
# }


=head3 _initialize

Initializes the logger.
Assigns all values to class variables.
Anything else that the _initialize function does.



=cut

# sub _initialize{
# 	my($self)=shift;

#     #logging

#     $self->logger(Log::Log4perl->get_logger()); 

#     $self->logger->info("Logger initialized in Example::Module::ClassTemplate");  

#     my %params = @_;

#     #on object construction set all parameters
#     foreach my $key(keys %params){
# 		if($self->can($key)){
# 			$self->$key($params{$key});
# 		}
# 		else{
# 			#logconfess calls the confess of Carp package, as well as logging to Log4perl
# 			$self->logger->logconfess("$key is not a valid parameter in Example::Module::ClassTemplate");
# 		}
# 	}	
# }



=head3 logger

Stores a logger object for the module.



=cut

# sub logger{
# 	my $self=shift;
# 	$self->{'_logger'} = shift // return $self->{'_logger'};
# }



=head3 setup

Sets the start and run modes and sets the parameters for connecting to the local database 



=cut

sub setup{
	my $self = shift;
	self->start_mode('hello');
	#Run modes are in the form of <referecence name> => <subname>
	$self->run_modes(
		'hello'=>'hello',
		'display'=>'displayHome',
		'single_strain'=>'singleStrain',
		'multi_strain'=>'mutliStrain',
		'bioinfo'=>'bioinfo'
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



=head3 displayHome

Displays the home page.



=cut

sub displayHome{
	my $self = shift;
	my $features = $self->_getAllData();
	my $featureRef = self->_hashData($features);
	my $template = $self->load_tmpl('display_home.tmpl' , die_on_bad_params=>0);
	$template->param(FEATURES=>$featureRef);
	return $template->output();
}



=head3 _getAllData

Queries the Chado database for feature table, sets returned data as an object variable.



=cut

sub _getAllData{
	my $self = shift;
	my $_features = $self->dbixSchema->resultset('Feature')->search(
		undef,
		{
			columns=>[qw/feature_id uniquename residues/]
		}
		);
	return $_features;
}



=head3 _hashData

Hashes feature data objects returned from database  



=cut

sub _hashData{
	my $self = shift;
	my $features = shift;
	my @featureData;
	while (my $featureRow = $features->next){
		my %featureRowData;
		$featureRowData{'FEATUREID'}=$featureRow->featureId;
		$featureRowData{'UNIQUENAME'}=$featureRow->uniquename;
		$featureRowData{'RESIDUES'}=$featureRow->residues;
		push(@featureData, \%featureRowData);
	}
	return \@featureData;
}


=head3 fourOhFour

Specifies the default/start mode to this. If a run mode is not set the prgram will croak()



=cut

sub fourOhFour {
	my $self = shift;
	my $template = $self->load_tmpl('four_oh_four.tmpl' , die_on_bad_params=>0);
	return $template->output();
}



=head3 singleStrain

Specifies the runmode for single_strain



=cut

sub singleStrain{
	my $self = shift;
	my $features = $self->_getAllData();
	my $featureRef = $self->_hashData($features);
	my $template = $self->load_tmpl('single_strain.tmpl' , die_on_bad_params=>0);
	$template->param(FEATURES=>$featureRef);
	return $template->output();
}



=head3 mmutliStrain

Specifies the runmode for multi_strain



=cut

sub multiStrain{
	my $self = shift;
	my $features = $self->_getAllData();
	my $featureRef = $self->_hashData($features);
	my $template = $self->load_tmpl('multi_strain.tmpl' , die_on_bad_params=>0);
	$template->param(FEATURES=>$featureRef);
	return $template->output();
}



=head3 bioinfo

Specifies the runmode for bioinfo



=cut

sub bioinfo {
	my $self = shift;
	my $template = $self->load_tmpl ( 'bioinfo.tmpl' , die_on_bad_params=>0 );
	return $template->output();
}



1;