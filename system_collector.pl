#!/usr/bin/perl
#
# 
# (https://github.com/andrem/VMwarePerfCollector)

use strict;
use warnings;
use VMware::VIRuntime;
use VMware::VILib;

$SIG{__DIE__} = sub{Util::disconnect() };

my $allCounters;
my $type = 'sys';
my $maxSample = 1;
          
my %physicalHost = ( 
    "server1.com" => [ "root", "X" ] , 
);

foreach my $host (keys %physicalHost ) {
    Util::connect(
        "https://" . $host . "/sdk/webService", 
        $physicalHost{$host}->[0], $physicalHost{$host}->[1] );

    my @msgs = GetPerformance($host);
    
    Util::disconnect();
}

sub GetPerformance {
    my ($ESXiServer) = @_;
    my $counters;
    my @perfMetricIds;
    my $host = Vim::find_entity_view(view_type => "HostSystem", filter => {'name' => $ESXiServer});
    my $perfmgrView = Vim::get_view(mo_ref => Vim::get_service_content()->perfManager);
    my $providerSummary = $perfmgrView->QueryPerfProviderSummary(entity => $host);
    my $perfCounterInfo = $perfmgrView->perfCounter;
    my $availmetricid = $perfmgrView->QueryAvailablePerfMetric(entity => $host);
    
    foreach (@$perfCounterInfo) {
        my $key = $_->key;
        $allCounters->{ $key } = $_;
        my $groupInfo = $_->groupInfo;
        if ($groupInfo->key eq $type) {
            $counters->{ $key } = $_;
        }
    }
    foreach (@$availmetricid) {
        if (exists $counters->{$_->counterId}) {
             my $metric = PerfMetricId->new (counterId => $_->counterId,instance => '*');
             push @perfMetricIds, $metric;
        }
    } 
    
    my $perfQuerySpec;
    $perfQuerySpec = PerfQuerySpec->new(entity => $host,
                                        metricId => \@perfMetricIds,
                                        'format' => 'csv',
                                        intervalId => $providerSummary->refreshRate, 
                                        maxSample => $maxSample );
   
    my $perfData;
    eval {
        $perfData = $perfmgrView->QueryPerf( querySpec => $perfQuerySpec);
    };

    PrintValues($perfData, $host);   
}

sub PrintValues {
    my ($data,$host) = @_;

    foreach (@$data) {
        my $hostname  = $host->name;
        my $timestamp = $_->sampleInfoCSV; 
        my $values    = $_->value;
        foreach (@$values) {
            my $counter = $allCounters->{$_->id->counterId};
            print "Counter: " . $counter->nameInfo->label . "\n";
            print "Description: " . $counter->nameInfo->summary . "\n";
            print "Instance: " . $_->id->instance . "\n";
            print "Units: " . $counter->unitInfo->label . "\n";
            print "Value: " . $_->value . "\n";
            print "-----------------------------------------------------\n";
        }
    }   
}
