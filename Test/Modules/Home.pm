#!/usr/bin/perl
package Modules::Home;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/..";
use parent 'Modules::App_Super';

sub setup{
	my $self=shift;

	$self->start_mode('display');
	$self->run_modes(
		'display'=>'display'
	);
}

sub display{
	my $self=shift;

	my $template = $self->load_tmpl('hello.tmpl', die_on_bad_params=>0);
	return $template->output();
}

1;


