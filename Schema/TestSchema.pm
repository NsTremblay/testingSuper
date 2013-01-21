#!/usr/bin/perl

use strict;
use warnings;

package TestApp::Schema::TestSchema;
use base qw/DBIx::Class::Schema/;

# Created a test schema in Perl for learning purposes.

__PACKAGE__->load_namespaces();

1;
