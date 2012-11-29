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
#            Soumya Deb (soumyad@yahoo-inc.com)
#

use strict;
use warnings;
use YAML;
use Echo::DnsMapper qw(calc_echo_servers allocate_echo_servers);
use Getopt::Long qw(:config no_ignore_case);
use Socket;
use Pod::Usage;

my %opts = (
        outfile => '-', # default to stdout
        );
GetOptions(
        'sites|s=s' => \$opts{'sites'},
        'calculate|c' => \$opts{'calculate'},
        'echoservers|e=s' => \$opts{'echoservers'},
        'outfile|o=s' => \$opts{'outfile'},
        'hosts|H' => \$opts{'hosts'},
        'help|h' => sub { pod2usage(-exitval => 0 , -verbose => 1) },
        'man|m' => sub { pod2usage(-exitval => 0 , -verbose => 2) },
        );

unless($opts{'sites'}) {
    pod2usage(
            -exitval => 2,
            -verbose => 1,
            -message => "--sites option is required",
            );
}

if(not defined $opts{'echoservers'} and not defined $opts{'calculate'}) {
    pod2usage(
            -exitval => 2,
            -verbose => 1,
            -message => "-echoservers option is required if --calculate is not specified",
            );
}

my $sites = YAML::LoadFile($opts{'sites'});
die "Failed reading site-origin mapping from file $opts{'sites'}" unless $sites;

if($opts{'calculate'}) {
    printf "Number of echo servers required: %d\n" , calc_echo_servers($sites);
    exit(0);
}

open(ECHO, "< $opts{'echoservers'}") or die "Error opening file $opts{'echoservers'}: $!";
my %dup;
my @echo_servers = grep { not m/^\s*$/ and not exists $dup{$_} and $dup{$_} = 1 } map { s/^\s*//;s/\s*$//;chomp; $_ } <ECHO>;
close(ECHO);

my $alloc = allocate_echo_servers($sites, \@echo_servers);
die "Echo server allocation failed" unless($alloc);

my $output = defined $opts{'hosts'} ? gen_hosts_file($alloc) : gen_dnsmap_file($alloc);
open(OUT, "> $opts{'outfile'}") or die "Unable to open $opts{'outfile'}: $!";
print OUT $output;
close(OUT);

#
# End of main
#
sub gen_hosts_file {
    my ($alloc) = @_;
    my $host_entries;
    my %echo_orig = ();
    while(my ($k,$v) = each(%$alloc)) {
        my $e = $v;
        $echo_orig{$e} ||= [];
        push(@{$echo_orig{$e}}, $k);
    }
    while(my ($k,$v) = each(%echo_orig)) {
        my $echo_ip_packed = gethostbyname($k);
        die "Unable to resolve address for $k" unless($echo_ip_packed);
        my $echo_ip = inet_ntoa($echo_ip_packed);
        $host_entries .= "# $k " . join(' ', @$v) . "\n";
        $host_entries .= "$echo_ip " . join(' ', @$v) . "\n";
    }
    return $host_entries;
}

sub gen_dnsmap_file {
    my ($alloc) = @_;
    my $dnsmaps= {};
    while(my ($k,$v) = each(%$alloc)) {
        $dnsmaps->{$k} = $v;
    }
    return YAML::Dump({ dnsmaps => $dnsmaps });
}

__END__

=head1 NAME

gen-dnsmap.pl - Generate dnsmap config file from site-origin maps

=head1 SYNOPSIS

gen-dnsmap.pl --sites|s=site_origin_file --calculate|c
              --sites|s=site_origin_file --echoservers|e=echo_server_list_file [--outfile|o=output_file] [--hosts|h]
              --help|h
              --man|m 

=head1 OPTIONS

=over 8

=item B<--sites|s>=filename

YAML file file containing Site-Origin mapping. A sample file:

    ---
    foo1.site.com:
      - orig1.site.com
      - orig2.site.com
    foo2.site.com:
      - orig3.site.com  
      - orig2.site.com

In the above YAML file we have two Sites (foo1.site.com and
foo2.site.com) which can be proxied to one of the origin servers listed
under them depending on the rules in the proxy server

=item B<--echoservers|e>=filename

File containing list of echo servers with one server on each line.

=item B<--calculate|c>

Calculate the list of echo servers required for the given Site-Origin
map. I<--echoservers> option need not be specified when this option
is specified.

=item B<--outfile|o>=filename

Write the output to the specified file

=item B<--hosts|h>

Give /etc/hosts stle output instead of dnsmap style used by test
client. This can be used as /etc/hosts or by dnsmasq kind of programs
in the proxy server for mapping origin servers to echo servers.

=item B<--help|h>

Print help message

=item B<--man|m>

Print full man page

=back

=cut
