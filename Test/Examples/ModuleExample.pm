#An example of a module in Perl
#

package ModuleExample;

#Note: in order to use this module in youre script you would just add 'use <ModuleName>'

#Package ModuleExample::SubNameSpace --> Modules can contian sub name spaces.

use strict;
use warnings;

#To use a function from a separate module in your Perl script you would simply type

#'<ModuleName>::module_function()'

#Note: to use functions from separate modules you must prvide the full path of the module where the function is accessed.


#If you have multiple functions from a single module that you would like to have availabe to a script you would use:
#This should be placed at the begining of your function.
use Exporter;

use vars qw(@ISA @EXPORT);

@ISA=qw(Exporter);

@EXPORT=("function1", "function2", "function3");

#I have saved this as a snippet called 'fnexp'

#You can also share variables from a module in your script using:

use vars qw($myvar1 @myvar2);

#Methods or functions go udner here:

1; #A module must always return a true value to the interpreter therefore we put a 1;
