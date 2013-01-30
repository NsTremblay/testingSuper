#Connecting to the database to get data

#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Database::Chado::TestSchema; #This is an error with the linter, not an issue with the code.
use Log::Log4perl qw(:easy);


# Connect to the database
my $schema = Database::Chado::TestSchema->connect('dbi:Pg:dbname=chado_db_test;host=localhost;port=5432', 'postgres', 'postgres');

# ResultSet for TestSchema;
#my $name_rs = $schema->resultset('Name of the resultset youre querying');  (Were probably most interested in the 'Feature' result set)

my $feature_rs = $schema->resultset('Feature')->search(
	undef,
		{
			columns=>[qw/feature_id organism_id uniquename/],
		}
	);

my $columnCount = 0;

#When using search you need to assign the acquired column as a new object so we can access each row's data
while (my $feature_row = $feature_rs->next){
	print $feature_row->feature_id . "\n";
	print $feature_row->uniquename . "\n";
	print $feature_row->organism_id . "\n";
	print ++$columnCount . "\n";
}