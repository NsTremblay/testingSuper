#!/usr/bin/perl

use strict;
use warnings;

package TestSchema;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/";

use parent qw/DBIx::Class::Schema/;

__PACKAGE__->load_namespaces();

1;