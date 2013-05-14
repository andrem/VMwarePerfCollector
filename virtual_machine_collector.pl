#!/usr/bin/perl
#
# 
# (https://github.com/andrem/VMwarePerfCollector)

use strict;
use warnings;
use VMware::VIRuntime;
use VMware::VILib;
use Data::Dumper;
use Time::HiRes qw(usleep nanosleep);

$SIG{__DIE__} = sub{Util::disconnect() };

my $PREFIX = "virtualMachine";
              
my %physical_host = ( 
    "server1.com" => [ "root", "X" ] , 
    "server2.com" => [ "root", "X" ] , 
    "server3.com" => [ "root", "X" ] , 
    "server4.com" => [ "root", "X" ] , 
    "server5.com" => [ "root", "X" ] , 
    "server6.com" => [ "root", "X" ] , 
    "server7.com" => [ "root", "X" ] , 
    "server8.com" => [ "root", "X" ] , 
    "server9.com" => [ "root", "X" ] , 
);

foreach my $host (keys %physical_host ) {
    Util::connect(
        "https://" . $host . "/sdk/webService", 
        $physical_host{$host}->[0], $physical_host{$host}->[1] );

    my @msgs = VMachine_state($host);
    
    foreach my $m (@msgs) {
         print "$m";
         #
         # and there is time to kill today ....
         #
         usleep(2000);
    }

    Util::disconnect();
}

sub VMachine_state {
    my ($host) = @_;
    my @return_msg = ();
 
    my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine');
    
    foreach my $vm (@$vm_views) {
        my $name = $vm->name;
        $name =~ s/ /\./g;
        $name = $host . "." . $PREFIX . "." . $name;
        my $msg;
        
        if ($vm->runtime->powerState->val eq 'poweredOn') {
            $msg = $name . ".powerState 1 " . time() . "\n";
            push(@return_msg, $msg);
        } else {
           $msg = $name . ".powerState 0 " . time() . "\n";
           push(@return_msg, $msg);
       }
    } 
    return @return_msg;
}
