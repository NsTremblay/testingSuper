#!/usr/bin/env perl

=pod

=head1 NAME

t::collections.t

=head1 SNYNOPSIS



=head1 DESCRIPTION

Tests for Modules::Collections

=head1 COPYRIGHT

This work is released under the GNU General Public License v3  http://www.gnu.org/licenses/gpl.htm

=head1 AUTHOR

Matt Whiteside (matthew.whiteside@phac-aspc.gov.gc)

=cut

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Modules::Dispatch;
use Modules::FormDataGenerator;
use Test::More;
use t::App;
use t::QuickDB;
use JSON::Any;
use Try::Tiny;

# Create Test Database instance
my $schema = t::QuickDB::connect();

# Add test-specific data to database
try {
    t::QuickDB::load_standard_groups( $schema );
}
catch {
    my $exception = $_;
    BAIL_OUT( 'Local test data creation failed: ' . $exception );
};

my $login_crudentials = t::QuickDB::login_crudentials();

# Create WWW::Mechanize CGIApp object
my $app = t::App::launch($schema);

# Collections::create tests
subtest 'Collections::Create - correct response to invalid parameters' => sub {
	my $fail = 0;

	diag "Not logged in";
	my $page = '/collections/create';
	$app->get_ok($page);
	my $json = t::App::json_ok($app);
	ok(valid_create_response($json, $fail), 'returned valid JSON object');
	note explain $json;

	diag "Logged in, missing group name";
	t::App::quickdb_login($app);
	$page = '/collections/create';
	$app->get_ok($page);
	$json = t::App::json_ok($app);
	ok(valid_create_response($json, $fail), 'returned valid JSON object');
	note explain $json;

	diag "Logged in, have group name, missing genome";
	$page = '/collections/create?name=TestGroup';
	$app->get_ok($page);
	$json = t::App::json_ok($app);
	ok(valid_create_response($json, $fail), 'returned valid JSON object');
	note explain $json;

};

subtest 'Collections::Create - create genome group' => sub {

	# Test inputs
	my $success = 1;
	my $name = 'Test Group';
	my $description = 'A new group';
	my $collection = 'A new collection';

	# Test genomes
	my ($good_genomes, $bad_genomes) = test_genomes($schema);
	ok(@$good_genomes == 6, 'test genome retrieval, accessible set') or 
		BAIL_OUT('Cannot obtain test set of genomes');
	ok(@$bad_genomes == 3, 'test genome retrieval, inaccessible set') or 
		BAIL_OUT('Cannot obtain test set of genomes');


	diag "Create group with no collection";
	my $page = "/collections/create";
	my $params = {
		name => $name,
		description => $description,
		genome => $good_genomes
	};
	$app->post_ok($page, $params, 'send create request to server');
	my $json = t::App::json_ok($app);
	ok(valid_create_response($json, $success), 'returned valid JSON object');
	note explain $json;

	my $group_id = $json->{group_id};
	validate_group($schema, $good_genomes, $group_id, $name, 'Individuals');


};



done_testing();

=head2 valid_create_response

Checks that the json object sent
from Collections::create has the required
keys: success, error.

A successful create operations should return
a group_id key and have success = TRUE.

=cut

sub json_response {
	my $json = shift;
	my $was_successful = shift;

	return 0 unless defined $json->{success};
	return 0 unless defined $json->{error};

	if($was_successful) {
		return 0 unless defined $json->{group_id};
	}

	return 1;
}

=head2 valid_create_response

Checks that the json object sent
from Collections::create has the required
keys: success, error.

A successful create operations should return
a group_id key and have success = TRUE.

=cut

sub valid_create_response {
	my $json = shift;
	my $was_successful = shift;

	return 0 unless defined $json->{success};
	
	if($was_successful) {
		return 0 unless defined $json->{group_id};
		return 0 unless $json->{success};
	} else {
		return 0 unless defined $json->{error};
		return 0 if $json->{success};
	}

	return 1;
}

=head2 test_genomes

Get mix of public & private
genomes for the test user,
as well as set of genomes not
accessible to test user.

=cut
sub test_genomes {
	my $schema = shift;

	my $user = t::QuickDB::user();
	my @genomes;

	# Public genomes
	my $public_rs = $schema->resultset('Feature')->search(
		{
			'type.name' => 'contig_collection'
		},
		{
			join => 'type',
			rows => 3,
			columns => ['feature_id']
		}
	);

	push @genomes, map { 'public_'.$_->feature_id } $public_rs->all;

	# Private genomes
	my $private_rs = $schema->resultset('PrivateFeature')->search(
		{
			'type.name' => 'contig_collection',
			'login.username' => $user
		},
		{
			join => ['type', { 'upload' => 'login' }],
			rows => 3,
			columns => ['feature_id']
		}
	);

	push @genomes, map { 'private_'.$_->feature_id } $private_rs->all;

	# Other user's private genomes
	my @bad_genomes;
	my $evil_user = t::QuickDB::evil_user();
	my $bad_rs = $schema->resultset('PrivateFeature')->search(
		{
			'type.name' => 'contig_collection',
			'login.username' => $evil_user
		},
		{
			join => ['type', { 'upload' => 'login' }],
			rows => 3,
			columns => ['feature_id']
		}
	);

	push @bad_genomes, map { 'private_'.$_->feature_id } $bad_rs->all;

	return (\@genomes, \@bad_genomes);
}

=head2 validate_group

Check if submitted genomes
have group assigned in DB

=cut
sub validate_group {
	my $schema = shift;
	my $genomes = shift;
	my $group_id = shift;
	my $group_name = shift;
	my $collection_name = shift;

	my $user = t::QuickDB::user();

	# Create DB interface object
	my $data = Modules::FormDataGenerator->new();
	$data->dbixSchema($schema);

	#$schema->storage->debug(1);

	# Check group assignments in meta-data JSON object
	my ($public_string, $private_string) = $data->genomeInfo($user);
	ok($public_string && $private_string, 'retrieved meta-data objects');
	
	my $public_json = eval {
		JSON::Any->jsonToObj($public_string);
	};
	ok($public_json, 'got JSON public meta-data object');
	diag explain $public_json;

	my $private_json = eval {
		JSON::Any->jsonToObj($private_string);
	};
	ok($private_json, 'got JSON private meta-data object');

	my $all_assigned = 1;
	foreach my $g (@$genomes) {
		my $genome_json;
		if($g =~ m/^public/) {
			$genome_json = $public_json->{$g};
		} 
		else {
			$genome_json = $private_json->{$g};
		}

		unless($genome_json && defined $genome_json->{groups}) {
			diag "$g genome does not have group array in meta-data object";
			diag explain $genome_json;
			$all_assigned = 0;
			last;
		}
		my $group_array = $genome_json->{groups};

		unless(grep(/^$group_id$/, @$group_array)) {
			diag "$g genome not assigned group $group_id";
			diag explain $genome_json;
			$all_assigned = 0;
			last;
		}
	}
	ok($all_assigned, 'genomes assigned proper group');

	# Check group added to group JSON
	my $found = 1;
	my ($group_string) = $data->userGroups($user);
	ok($group_string, 'retrieved groups objects');
	
	my $group_json = eval {
		JSON::Any->jsonToObj($group_string);
	};
	ok($group_json, 'got JSON group object');

	ok(defined($group_json->{custom}) && @{$group_json->{custom}}, 'found custom genome groups');

	my $found_collection = 0;
	my $collection_json;
	foreach my $collection (@{$group_json->{custom}}) {
		if($collection->{name} eq $collection_name) {
			$found_collection = 1;
			$collection_json = $collection;
			last;
		}
	}
	ok($found_collection, 'found group collection');
	
	my $found_group = 0;
	my $this_group_json;
	foreach my $group (@{$collection_json->{children}}) {
		if($group->{name} eq $group_name) {
			$found_group = 1;
			$this_group_json = $group;
			last;
		}
	}
	ok($found_collection, 'found group');
	ok($this_group_json->{id} == $group_id, 'group IDs match');

	return;
}







