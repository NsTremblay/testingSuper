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
    print STDERR $ENV{PATH_INFO};
    return {
        prefix  => 'Modules',
        args_to_new=>{
                TMPL_PATH=>"$SCRIPT_LOCATION/../App/Templates/"
        },
        table   => [
                '' =>           {app=>'Home' , rm=>'home'},
                '/' =>          {app=>'Home', rm=>'home'},
                '/hello' =>     {app=>'Home' , rm=>'default'},
                '/home' =>      {app=>'Home', rm=>'home'},
                '/strain_info' => {app=>'StrainInfo', rm=>'strain_info'},
                '/group_wise_comparisons' => {app=>'GroupWiseComparisons', rm=>'group_wise_comparisons'},
                '/genome_uploader' => {app=>'GenomeUploader', rm=>'genome_uploader'},
                '/upload_genome' => {app=>'GenomeUploader', rm=>'upload_genome'},
                '/virulence_factors' =>   {app=>'VirulenceFactors' , rm=>'virulence_factors'},
                '/statistics' =>    {app=>'Statistics' , rm=>'stats'}
        ],
    };
}

1;