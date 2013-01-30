#Connecting to the database to get data

#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../Perl/";
use Database::Chado::TestSchema;
use Log::Log4perl qw(:easy);

# Connect to the database
my $schema = Database::Chado::TestSchema->connect('dbi:Pg:dbname=chado_db_test;host=localhost;port=5432', 'postgres', 'postgres');



# ResultSet for TestSchema;
#my $name_rs = $schema->resultset('Name of the resultset youre querying');  (Were probably most interested in the 'Feature' result set)

#This will query the db for all Features
my $feature_rs = $schema->resultset('Feature');
