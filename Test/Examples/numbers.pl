#!/usr/bin/perl

use strict;
use warnings;

my $x = 1;
my $y = 0;
print "2^", $y, "=", $x, "\n";
$x *= 2; $y += 1;
print "2^", $y, "=", $x, "\n";
$x *= 2; $y += 1;
print "2^", $y, "=", $x, "\n";
$x *= 2; $y += 1;
print "2^", $y, "=", $x, "\n";
$x *= 2; $y += 1;
print "2^", $y, "=", $x, "\n";
$x *= 2; $y += 1;
print "2^", $y, "=", $x, "\n";

print "Please enter your name:\n";
my $name = <>;
chomp($name);
print "Hello, ", $name, "!\n";

print "Please enter the length of the pyramid:\n";
my $size = <>;
chomp($size);

ROW_LOOP: for my $row (1 .. $size)
{
    for my $column (1 .. ($size+1))
    {
        if ($column > $row)
        {
            print "\n";
            next ROW_LOOP;
        }
        print "#";
    }
}