#!/usr/bin/perl

=pod

=head1 NAME

Example::Module::ClassTemplate - A Class that provides the following functionality:

=head1 SYNOPSIS


	use Example::Module::ClassTemplate;
	
	my $obj = Example::Module::ClassTemplate->new(
		'param1'=>'setting1',
		'param2'=>'setting2'
	);
	$obj->method1;
	$obj->method2;

=head1 DESCRIPTION

This module is explained here.

=cut

=head1 ACKNOWLEDGEMENTS

Thanks.

=head1 COPYRIGHT

This work is released under the GNU General Public License v3  http://www.gnu.org/licenses/gpl.html

=head1 AVAILABILITY

The most recent version of the code may be found at: 

=head1 AUTHOR

Your name (yourname@email.com)

=head2 Methods

=cut


package Example::Module::ClassTemplate;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Log::Log4perl;
use Carp; #this enables a stack trace unlike warn/die

#object creation
sub new {
	my ($class) = shift;
	my $self = {};
	bless( $self, $class );
	$self->_initialize(@_);
	return $self;
}


=head3 _initialize

Initializes the logger.
Assigns all values to class variables.
Anything else that the _initialize function does.



=cut

sub _initialize{
	my($self)=shift;

    #logging

    $self->logger(Log::Log4perl->get_logger()); 

    $self->logger->info("Logger initialized in Example::Module::ClassTemplate");  

    my %params = @_;

    #on object construction set all parameters
    foreach my $key(keys %params){
		if($self->can($key)){
			$self->$key($params{$key});
		}
		else{
			#logconfess calls the confess of Carp package, as well as logging to Log4perl
			$self->logger->logconfess("$key is not a valid parameter in Example::Module::ClassTemplate");
		}
	}	
}



=head3 logger

Stores a logger object for the module.

=cut

sub logger{
	my $self=shift;
	$self->{'_logger'} = shift // return $self->{'_logger'};
}


=head3 param1

A description of the class parameter goes here.

=cut

sub param1{
	my $self=shift;
	$self->{'_param1'}=shift // return $self->{'_param1'};
}

#etc ...


=head3 method1

A description of method1 goes here

=cut

sub method1{
	my $self=shift;
	$self->{'_method1'}=shift // return $self->{'_method1'};
}

# etc ...

1;