#!perl

use strict;
use warnings;

use Time::Duration;
use Number::Format qw(:subs);
use Proc::ProcessTable;
use Data::Google::Visualization::DataTable;

sub {
    my $env = shift;

    # Local addresses only!


    use Data::Printer; p $env;

    my $datatable = Data::Google::Visualization::DataTable->new();
    $datatable->add_columns(
        { id => 'pid',   label => "PID",     type => 'number', },
        { id => 'uid',   label => "User",    type => 'number', },
        { id => 'size',  label => "Size",    type => 'number', },
        { id => 'cmd',   label => "Command", type => 'string', },
        { id => 'since', label => "Since",   type => 'datetime' },
    );

    foreach my $p (@{ Proc::ProcessTable->new()->table() }) {

        # Only show processes for this user
        next unless $p->{'uid'} == $>;

        $datatable->add_rows({
            pid   => $p->{'pid'},
            uid   => { v => $p->{'uid'},  f => (getpwuid( $p->{'uid'} ))[0] },
            size  => { v => $p->{'size'}, f => format_bytes( $p->{'size'} ) },
            cmd   => $p->{'cmndline'},
            since => { v => $p->{'start'}, f => ago( time - $p->{'start'} ) }
        });
    }

}