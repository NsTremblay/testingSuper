#!/usr/bin/perl

use strict;
use warnings;
use Log::Log4perl qw(:easy); #easy provides a beginners interface to learn the system

#In Log4perl logger obhects do the work and they are obtained by calling get_logger();
#This effectively returns a reference to a logger, and this can be called by all the functions