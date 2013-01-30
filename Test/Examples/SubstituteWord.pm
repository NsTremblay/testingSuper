#!/usr/bin/env/perl

package SubstituteWord;

use warnings;
use strict;

sub new
{
    # Retrieve the package's string.
    # It is not necessarily Foo, because this constructor may be
    # called from a class that inherits Foo.
    my $class = shift;
   
    # $self is the the object. Let's initialize it to an empty hash
    # reference.
    my $self = {};

    # Associate $self with the class $class. This is probably the most
    # important step.
    bless $self, $class;

  	 # Return $self so the user can use it.

  	 #call init
  	$self->_initialize(@_);
    return $self;
}


sub _initialize{
	my $self=shift;

	my %params = @_;

	$self->fileName($params{'fileName'}) // print "fileName has not been initialized\n";
	$self->lastName($params{'lastName'}) // 1;
	$self->firstName($params{'firstName'}) // 1;


}


#This is  the equivalent of a get/set method in one inline method.

# // used in the following context as a logical or operator but not quite the same as ||
# Example

# EXPR1 // EXPR2 it checks to see whether EXPR1 is defined (not so much whether it is true) otherwise it evaluates EXPR2

sub fileName{
	my $self=shift;

	$self->{'_fileName'} = shift // return $self->{'_fileName'};
}


sub firstName{
	my $self=shift;
	$self->{'_firstName'} = shift // return $self->{'_firstName'};
}


sub lastName{
	my $self=shift;
	$self->{'_lastName'} = shift // return $self->{'_lastName'};
}

#methods

1;