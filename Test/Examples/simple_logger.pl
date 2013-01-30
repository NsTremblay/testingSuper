#!/usr/bin/perl

use strict;
use warnings;
use Log::Log4perl qw(:easy);  #Right now we just want to use a simple interface to test out our logger

#In Log4perl there are 5 log levels from least to most severe:

# DEBUG
# INFO
# WARN
# ERROR
# FATAL

#For the time being lets just output messages from INFO onwards

Log::Log4perl->easy_init($INFO); #Basically initializes a logger in easy mode and we specify that we want
#to log events only at the level of info onwards.

#We can also create a appender to explicity state where the log should be written to,

# # Appender
# my $appender = Log::Log4perl::Appender->new(
# 	"Log::Dispatch::Screen",
# 	#filename => "simple_logger_log.log",
# 	#mode => "append"
# 	);

#We can also modify the output of the appender (See appander documentation for detail)

blood_type();
blood_type("AB+");
blood_type("O");

sub blood_type{
	my $what = shift;

	my $logger = get_logger();

	if(defined $what){
		$logger->info("Blood Type is : ", $what);
		 if ($what eq "O") {
		 	$logger->warn("This person is a universal blood donor");
		 	} else {
		 		1;
		 	}
	} else {
		$logger->error("No Blood Type indicated");
	}
}

#Note that the output from this program is:

# 2013/01/11 09:13:51 No Blood Type indicated
# 2013/01/11 09:13:51 Blood Type is : AB+