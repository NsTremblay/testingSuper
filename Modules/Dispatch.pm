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
                'user/login'          => { app => 'User', rm => 'authen_login' },
                ':app/:rm'            => { },
                'start'               => { app => 'DisplayTest', rm => 'display' },
#                'login'               => { app => 'User', rm => 'authen_login' },
#                'logout'              => { app => 'User', rm => 'logout' },
#                'create_account'      => { app => 'User', rm => 'create_account' },
#                'new_account'         => { app => 'User', rm => 'new_account' },
#                'update_account'      => { app => 'User', rm => 'update_account' },
#                'edit_account'        => { app => 'User', rm => 'edit_account' },
#                'forgot_password'     => { app => 'User', rm => 'forgot_password' },
#                'email_password'      => { app => 'User', rm => 'email_password' },
                'test'                => { app => 'User', rm => 'hello' }  
        ],
    };
}

1;