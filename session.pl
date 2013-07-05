#!/usr/bin/perl
#
# 
#

use strict;
use warnings;
use VMware::VIRuntime;
use VMware::VILib;
use Term::ANSIColor;

$SIG{__DIE__} = sub{Util::disconnect() };
              
my %physical_host = ( 
    "server1" => [ "root", "XXXX" ] , 
);

foreach my $host (keys %physical_host ) {
    if ( -e "/tmp/$host" ) {
        print "Using session file: /tmp/$host\n";
        Vim::load_session(session_file => "/tmp/$host"); 
    } else {
        print "Creating session file: /tmp/$host\n";

        Util::connect(
            "https://" . $host . "/sdk/webService", 
            $physical_host{$host}->[0], $physical_host{$host}->[1] );

        Vim::save_session(session_file => "/tmp/$host");
    }
    VMachine_state($host);

    Util::disconnect();
}

sub VMachine_state {
    my ($host) =@_;

    my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine');
    
    foreach my $vm (@$vm_views) {
       print colored ['yellow'], ' Virtual machine:', ;
       print " " . $vm->name . "\n";
    }
}

