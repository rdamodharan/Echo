#!/usr/bin/env perl
# Copyright(c) 2012 Yahoo! Inc. All rights reserved. 
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License. See accompanying LICENSE file. 
#
# Author(s): Damodharan Rajalingam (damu@yahoo-inc.com)
#
use strict;
use warnings;
use Getopt::Long;
use YAML;
use Echo::Config;
use Log::Log4perl;
use Text::TabularDisplay;
use Data::Dumper;

my %opts = (  
        'server' => 'localhost',
        );

my $logger_conf = <<LOGCONF
log4perl.rootLogger = sub { return get_rootlogger_conf() }
log4perl.appender.Stderr=Log::Log4perl::Appender::Screen
log4perl.appender.Stderr.stderr=0
log4perl.appender.Stderr.layout=PatternLayout
log4perl.appender.Stderr.layout.ConversionPattern=%p> %m%n
LOGCONF
;

GetOptions(
        '--server|s=s' => \$opts{'server'},
        '--help|h' => sub { print_usage(); exit(0) },
        '--verbose|v' => \$opts{'verbose'},
        );

unless(@ARGV) {
    print STDERR "Specify some test case files\n";
    print_usage();
    exit(2);
}

Log::Log4perl::init(\$logger_conf);
my $logger = Log::Log4perl::get_logger();

my $cfg = Echo::Config->new();

foreach my $file (@ARGV) {
    $logger->info("Loading config file $file...");
    $cfg->add_config_file($file);
}

my ($total_hosts,$success_hosts,$failed_hosts) = (0,0,0);
my @summary=();
foreach my $host ($cfg->get_host_list()) {
    my $h = $cfg->get_host($host);
    my @_sites = $h->get_aliases(); # aliases defined for the site
    unshift(@_sites, $h->name()); # actual name of the site
    foreach my $alias ( @_sites ) { # for each name defined for the site
        my ($total_tests, $success_tests, $failed_tests) = $h->run_tests_for_alias($alias,$opts{'server'});
        $total_hosts++;
        $failed_tests>0 ? $failed_hosts++ : $success_hosts++;
        push(@summary, [ $alias, ($failed_tests>0 ? 'FAIL' : 'PASS'), $total_tests, $success_tests, $failed_tests ]);
    }
}

$logger->info("Total hosts tested: $total_hosts, Successful: $success_hosts, Failed: $failed_hosts");
$logger->info("Summary of tests\n" . get_summary(\@summary));

exit( $failed_hosts>0 ? 2 : 0 );
#
# End of main
#

sub get_rootlogger_conf {
    my $priority=$opts{'verbose'}?'TRACE':'INFO';
    return "$priority, Stderr";
}


sub print_usage {
    print <<USAGE
Usage: $0 [--verbose] [--server|s=servername[:port]] file1.yml ... [filen.yml]
       $0 --help

If no server is provided localhost will be assumed as the proxy server to be tested.
The YAML files have the test case specifications. Please look at Test Specification Format
for more information

USAGE
}

sub get_summary {
    my ($data) = @_;
    my $table = Text::TabularDisplay->new(qw(Site Status Total_Tests Success Failed));
    foreach my $row (@$data) {
        $table->add(@$row);
    }
    return $table->render();
}
