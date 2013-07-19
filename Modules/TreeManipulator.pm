#!/usr/bin/env perl

package Modules::TreeManipulator;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/..";
use IO::File;
use Log::Log4perl qw(:easy);
use Carp;

sub new {
	my ($class) = shift;
	my $self = {};
	bless( $self, $class );
	$self->_initialize(@_);
	return $self;
}

sub _initialize {
	my ($self) = shift;

	#logging
	$self->logger(Log::Log4perl->get_logger());
	$self->logger->info("Logger initialized in Modules::TreeManipulator");
	
	my %params = @_;
	#object construction set all parameters
	foreach my $key(keys %params){
		if($self->can($key)){
			$self->key($params{$key});
		}
		else {
			#logconfess calls the confess of Carp package, as well as logging to Log4perl
			$self->logger->logconfess("$key is not a valid parameter in Modules::TreeManipulator");
		}
	}
}

sub logger {
	my $self = shift;
	$self->{'_logger'} = shift // return $self->{'_logger'};
}

sub inputDirectory {
	my $self = shift;
	$self->{'_inputDirectory'} = shift // return $self->{'_inputDirectory'};
}

sub newickFile {
	my $self = shift;
	$self->{'_newickFile'} = shift // return $self->{'_newickFile'};
}

sub outputDirectory {
	my $self = shift;
	$self->{'_outputDirectory'} = shift // return $self->{'_outputDirectory'};
}

sub outputTree {
	my $self = shift;
	$self->{'_outputTree'} = shift // return $self->{'_outputTree'};
}

sub cssFile {
	my $self = shift;
	$self->{'_cssFile'} = shift // return $self->{'_cssFile'};
}

#This method was adapted from the Salmonella Serotyper Platform
sub _pruneTree {
	my $self=shift;
	my $namesArrayRef=shift;

	my $timeStamp = localtime(time);
	$timeStamp =~ s/ /_/g;
	$timeStamp =~ s/:/_/g;

	$self->outputDirectory("../../Phylogeny/NewickTrees/");
	$self->outputTree("tempGroup$timeStamp.svg");

	my $systemLine;
	if($namesArrayRef->[0]){
		$systemLine = 'nw_prune -v ' . $self->inputDirectory() . $self->newickFile() . ' ';
		foreach my $name(@{$namesArrayRef}){
			$systemLine .=$name . ' ';
		}
	}
	else{
	}
	$systemLine .= ' | nw_rename - ' . $self->inputDirectory() . 'pub_common_names.map';
	$systemLine .= '| nw_display -sS -w 900 -b \'opacity:0\' - > ' . $self->outputDirectory() . $self->outputTree();
	system($systemLine);
}

sub _getNearestClades {
	my $self=shift;
	my $strainID = shift;

	my $timeStamp = localtime(time);
	$timeStamp =~ s/ /_/g;
	$timeStamp =~ s/:/_/g;

	$self->outputDirectory("../../Phylogeny/NewickTrees/");
	$self->outputTree("temp$timeStamp.svg");
	$self->cssFile("css$timeStamp.map");

	#Make a css.map file for each tree
	#Need to iterate through the pub_common_name.map file to find the right tag
	open my $in, '<' , $self->outputDirectory . 'pub_common_names.map';
	my $tagLabel;
	while (<$in>) {
		if ($_ =~ /$strainID/) {
			$tagLabel = $_;
			$tagLabel =~ s/$strainID//g;
			$tagLabel =~ s/\t//g;
			last;
		}
		else{
			$tagLabel = $strainID;
		}
	}

	open my $out, '>' , $self->outputDirectory . $self->cssFile();
	print $out 'font-style:italic;stroke:red; I ' . $tagLabel;
	close $out;

	my $systemLine = 'nw_clade -c 3 ' . $self->inputDirectory() . $self->newickFile() . ' ' . $strainID;
	$systemLine .= ' | nw_rename - ' . $self->inputDirectory() . 'pub_common_names.map';
	$systemLine .= ' | nw_display -sS -w 700 -b \'opacity:0\' -c '. $self->outputDirectory() . $self->cssFile() .' - > ' . $self->outputDirectory() . $self->outputTree();

	system($systemLine);
}

1;