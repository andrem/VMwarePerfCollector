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
);

foreach my $host (keys %physical_host ) {
    Util::connect(
        "https://" . $host . "/sdk/webService", 
        $physical_host{$host}->[0], $physical_host{$host}->[1] );

    my @msgs = DiskPerfCollector($host);
    
    foreach my $m (@msgs) {
         print "$m";
         #
         # and there is time to kill today ....
         #
         usleep(2000);
    }

    Util::disconnect();
}

sub DiskPerfCollector {
    my ($ESXiServer) = @_;
    my $type = 'sys';
    my $counters;
    my @perf_metric_ids; 
    my $all_counters;
    my $perf_query_spec;
    my $perf_data;
 
    my $host = Vim::find_entity_views(view_type => 'HostSystem', filter => {'name' => $ESXiServer});
    my $perfmgr_view = Vim::get_view(mo_ref => Vim::get_service_content()->perfManager);
    my $perfCounterInfo = $perfmgr_view->perfCounter;
    my $availmetricid = $perfmgr_view->QueryAvailablePerfMetric(entity => $host);
    foreach (@$perfCounterInfo) {
        my $key = $_->key;
        $all_counters->{ $key } = $_;
        my $group_info = $_->groupInfo;
        if ($group_info->key eq $type) {
            $counters->{ $key } = $_;
        }
    }
    foreach (@$availmetricid) {
        if (exists $counters->{$_->counterId}) {
             my $metric = PerfMetricId->new (counterId => $_->counterId,instance => (Opts::get_option('instance') || ''));
             push @perf_metric_ids, $metric;
        }
    }

    my $historical_intervals = $perfmgr_view->historicalInterval;
    my $provider_summary = $perfmgr_view->QueryPerfProviderSummary(entity => $host);
    my @intervals;
    
    if ($provider_summary->refreshRate) {
        push @intervals, $provider_summary->refreshRate;
    }

    foreach (@$historical_intervals) {
        push @intervals, $_->samplingPeriod;
    }
    
    $perf_query_spec = PerfQuerySpec->new(entity => $host, metricId => \@perf_metric_ids, 'format' => 'csv', intervalId => shift @intervals, maxSample => '');

    print Dumper($perf_query_spec);
}
