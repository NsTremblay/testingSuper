#!/usr/bin/perl

use strict;
use warnings;
use DBIx::Class::Schema::Loader qw/ make_schema_at /;

make_schema_at(
	'Database::Chado::Schema',
	{ debug => 1, 
	dump_directory => '/home/matt/workspace/a_genodo/sandbox/'},
	[ 'dbi:Pg:dbname=genodo;host=localhost;port=5432', 'postgres', '',  ],
	);
