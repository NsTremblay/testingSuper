#!/usr/bin/perl

use strict;
use warnings;
use DBIx::Class::Schema::Loader qw/ make_schema_at /;

make_schema_at(
	'TestSchema',
	{ debug => 1, 
	dump_directory => '/home/amanji/Projects/Perl/Database/Chado'},
	[ 'dbi:Pg:dbname=chado_db_test;host=localhost;port=5432', 'postgres', 'postgres',  ],
	);