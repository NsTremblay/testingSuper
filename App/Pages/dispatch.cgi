#!/usr/bin/perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../";
use Modules::Dispatch;

Modules::Dispatch->dispatch();

1;
