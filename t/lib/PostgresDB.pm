#!/usr/bin/env perl

=pod

=head1 NAME

t::lib::PostgresDB;

=head1 SNYNOPSIS

my $schema = t::lib::PostgresDB::connect()

=head1 DESCRIPTION

Creates a test database 

=head1 COPYRIGHT

This work is released under the GNU General Public License v3  http://www.gnu.org/licenses/gpl.htm

=head1 AUTHOR

Matt Whiteside (matthew.whiteside@phac-aspc.gov.gc)

=cut

package t::lib::PostgresDB;

use strict;
use warnings;

use Class::Accessor::Lite;
use Cwd;
use DBI;
use POSIX qw(SIGTERM WNOHANG setuid);

our $errstr;

our %Defaults = (
    auto_start      => 2,
    pid             => undef,
    _owner_pid      => undef,
);

Class::Accessor::Lite->mk_accessors(keys %Defaults);

sub new {
    my $klass = shift;

    my $self = bless {
        %Defaults,
        @_ == 1 ? %{$_[0]} : @_,
        _owner_pid => $$,
    }, $klass;

    if($ENV{USER} ne 'postgres') {
       die "Must run as user postgres.";
    }
   

    if ($self->auto_start) {
        $self->setup
            if $self->auto_start >= 2;
        $self->start;
    }
    $self;
}

sub DESTROY {
    my $self = shift;
    $self->stop
        if defined $self->pid && $$ == $self->_owner_pid;
}

sub dsn {
    my ($self, %args) = @_;
    $args{host}   ||= 'localhost';
    $args{port}   ||= '54321';  
    $args{user}   ||= 'postgres';
    $args{dbname} ||= 'testodo';
    return 'DBI:Pg:' . join(';', map { "$_=$args{$_}" } sort keys %args);
}

sub start {
    my $self = shift;
    return
        if defined $self->pid;
    # start (or die)
    sub {
        my $err;
        if ($self->port) {
            $err = $self->_try_start($self->port)
                or return;
        } else {
            # try by incrementing port no
            for (my $port = $BASE_PORT; $port < $BASE_PORT + 100; $port++) {
                $err = $self->_try_start($port)
                    or return;
            }
        }
        # failed
        die "failed to launch postgresql:$!\n$err";
    }->();
    { # create "test" database
        my $dbh = DBI->connect($self->dsn(dbname => 'template1'), '', '', {})
            or die $DBI::errstr;
        if ($dbh->selectrow_arrayref(q{SELECT COUNT(*) FROM pg_database WHERE datname='test'})->[0] == 0) {
            $dbh->do('CREATE DATABASE test')
                or die $dbh->errstr;
        }
    }
}

sub _try_start {
    my ($self, $port) = @_;
    # open log and fork
    open my $logfh, '>', $self->base_dir . '/postgres.log'
        or die 'failed to create log file:' . $self->base_dir
            . "/postgres.log:$!";
    my $pid = fork;
    die "fork(2) failed:$!"
        unless defined $pid;
    if ($pid == 0) {
        open STDOUT, '>&', $logfh
            or die "dup(2) failed:$!";
        open STDERR, '>&', $logfh
            or die "dup(2) failed:$!";
        chdir $self->base_dir
            or die "failed to chdir to:" . $self->base_dir . ":$!";
        if (defined $self->uid) {
            setuid($self->uid)
                or die "setuid failed:$!";
        }
        my $cmd = join(
            ' ',
            $self->postmaster,
            $self->postmaster_args,
            '-p', $port,
            '-D', $self->base_dir . '/data',
            '-k', $self->base_dir . '/tmp',
        );
        exec($cmd);
        die "failed to launch postmaster:$?";
    }
    close $logfh;
    # wait until server becomes ready (or dies)
    for (my $i = 0; $i < 100; $i++) {
        open $logfh, '<', $self->base_dir . '/postgres.log'
            or die 'failed to open log file:' . $self->base_dir
                . "/postgres.log:$!";
        my $lines = do { join '', <$logfh> };
        close $logfh;
        last
            if $lines =~ /is ready to accept connections/;
        if (waitpid($pid, WNOHANG) > 0) {
            # failed
            return $lines;
        }
        sleep 1;
    }
    # postgresql is ready
    $self->pid($pid);
    $self->port($port);
    return;
}

sub stop {
    my ($self, $sig) = @_;
    return
        unless defined $self->pid;
    $sig ||= SIGTERM;
    kill $sig, $self->pid;
    while (waitpid($self->pid, 0) <= 0) {
    }
    $self->pid(undef);
}

sub setup {
    my $self = shift;
    # (re)create directory structure
    mkdir $self->base_dir;
    chmod 0755, $self->base_dir
        or die "failed to chmod 0755 dir:" . $self->base_dir . ":$!";
    if ($ENV{USER} eq 'root') {
        chown $self->uid, -1, $self->base_dir
            or die "failed to chown dir:" . $self->base_dir . ":$!";
    }
    if (mkdir $self->base_dir . '/tmp') {
        if ($self->uid) {
            chown $self->uid, -1, $self->base_dir . '/tmp'
                or die "failed to chown dir:" . $self->base_dir . "/tmp:$!";
        }
    }
    # initdb
    if (! -d $self->base_dir . '/data') {
        pipe my $rfh, my $wfh
            or die "failed to create pipe:$!";
        my $pid = fork;
        die "fork failed:$!"
            unless defined $pid;
        if ($pid == 0) {
            close $rfh;
            open STDOUT, '>&', $wfh
                or die "dup(2) failed:$!";
            open STDERR, '>&', $wfh
                or die "dup(2) failed:$!";
            chdir $self->base_dir
                or die "failed to chdir to:" . $self->base_dir . ":$!";
            if (defined $self->uid) {
                setuid($self->uid)
                    or die "setuid failed:$!";
            }
            my $cmd = join(
                ' ',
                $self->initdb,
                $self->initdb_args,
                '-D', $self->base_dir . '/data',
            );
            exec($cmd);
            die "failed to exec:$cmd:$!";
        }
        close $wfh;
        my $output = '';
        while (my $l = <$rfh>) {
            $output .= $l;
        }
        close $rfh;
        while (waitpid($pid, 0) <= 0) {
        }
        die "*** initdb failed ***\n$output\n"
            if $? != 0;
    }
}



1;