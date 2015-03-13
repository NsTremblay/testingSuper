#!/usr/bin/env perl

=pod

=head1 NAME

t::shiny.t

=head1 SNYNOPSIS

perl t/shiny.t

=head1 DESCRIPTION

Tests for Modules::Shiny

Must be run parent directory (directory above t/) so that Test::DBIx::Class can find
the etc directory.

=head1 COPYRIGHT

This work is released under the GNU General Public License v3  http://www.gnu.org/licenses/gpl.htm

=head1 AUTHOR

Matt Whiteside (matthew.whiteside@phac-aspc.gov.gc)

=cut

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Database::Chado::Schema;
use Test::More;
use Test::Exception;
use Data::Bridge;
use Data::Grouper;
use Modules::FormDataGenerator;
use Test::DBIx::Class;
use t::lib::App;
use Config::Simple;
use File::Temp qw/tempdir/;

# Install DB data
fixtures_ok 'basic'
	=> 'Install basic fixtures from configuration files';

# Initialize DB interface objects via Bridge module
ok my $dbBridge = Data::Bridge->new(schema => Schema), 
	'Create Data::Bridge object';

ok my $data = Modules::FormDataGenerator->new(dbixSchema => $dbBridge->dbixSchema, cvmemory => $dbBridge->cvmemory), 
	'Create Module::FormDataGenerator object';

# Grouping object
ok my $grouper = Data::Grouper->new(schema => $dbBridge->dbixSchema, cvmemory => $dbBridge->cvmemory), 
	'Create Data::Grouper object';


# Create test CGIApp and work environment
my $cgiapp;
lives_ok { $cgiapp = t::lib::App::launch(Schema, $ARGV[0]) } 'Test::WWW::Mechanize::CGIApp initialized';
BAIL_OUT('CGIApp initialization failed') unless $cgiapp;


# Group genomes into standard groups
fixtures_ok sub {
	my $schema = shift;

	# Retrieve some user ID, just need a placeholder
	my $user = $schema->resultset('Login')->find(2);
	die "Error: no users loaded" unless $user;

    # Perform update / creation of standard groups
    $grouper->updateStandardGroups($data, $user->username);

    return 1;
  
}, 'Install standard group fixtures';


# Login
my $login_id = 1;
my $username = Login->find(1)->username;
t::lib::App::login_ok('testbot', 'password');



# Create custom groups
fixtures_ok sub {
	my $schema = shift;

	# Get some genome IDs for groups
	my $public_rs = Feature->search(
		{
			'type.name' => 'contig_collection'
		},
		{
			join => ['type']
			rows => 10
			columns => ['feature_id']
		}
	);

	my $private_rs = Feature->search(
		{
			'type.name' => 'contig_collection'
		},
		{
			join => ['type']
			rows => 10
			columns => ['feature_id']
		}
	);


	my @group1;
	my @group2;
	my $i = 0;
	while(my $row = $public_rs->next) {

		if($i < 5) {
			push @group1, 'public_'.$row->feature_id;
		}
		else {
			push @group2, 'public_'.$row->feature_id;
		}
	}



}, 'Install custom group fixtures';






done_testing();

########
## SUBS
########



=head2 shiny_get_request


=cut
sub shiny_get_request {
	
}

