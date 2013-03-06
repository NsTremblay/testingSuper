#!/usr/bin/perl
package Modules::Dispatch;

# mod_rewrite alters the PATH_INFO by turning it into a file system path,
# so we repair it.
#from https://metacpan.org/module/CGI::Application::Dispatch#DISPATCH-TABLE

$ENV{PATH_INFO} =~ s/^$ENV{DOCUMENT_ROOT}// if defined $ENV{PATH_INFO};

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/..";
use parent qw/CGI::Application::Dispatch/;
use File::Basename;

#get script location via File::Basename
my $SCRIPT_LOCATION = dirname(__FILE__);


sub dispatch_args {
    return {
        prefix  => 'Modules',
        args_to_new=>{
                TMPL_PATH=>"$SCRIPT_LOCATION/../App/Templates/"
        },
        table   => [
                '' =>           {app=>'DisplayTest' ,rm=>'display'},
                '/' =>          {app=>'DisplayTest',rm=>'display'},
                '/test' =>      {app=>'DisplayTest',rm=>'display'},
                '/hello' =>     {app=>'DisplayTest' , rm=>'hello'},
                '/home' =>      {app=>'Home', rm=>'display'},
                '/single_strain' => {app=>'DisplayTest', rm=>'single_strain'},
                '/multi_strain' => {app=>'DisplayTest', rm=>'multi_strain'},
                '/bioinfo' =>   {app=>'DisplayTest' , rm=>'bioinfo'},
                '/single_strain/ss' => {app=>'DisplayTest', rm=>'process_single_strain_form'},
                '/multi_strain/ms' => {app=>'DisplayTest', rm=>'process_multi_strain_form'}
        ],
    };
}

1;