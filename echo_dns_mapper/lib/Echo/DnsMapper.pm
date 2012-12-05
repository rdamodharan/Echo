#!/usr/bin/env perl
#
# Copyright (c) 2012, Yahoo! Inc. All rights reserved.
#
# This program is free software. You may copy or redistribute it under
# the same terms as Perl itself. Please see the LICENSE.txt file included
# with this project for the terms of the Artistic License under which this
# project is licensed.
#
# Author(s): Damodharan Rajalingam (damu@yahoo-inc.com)
#

package Echo::DnsMapper;
use strict;
use warnings;
use Carp;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(allocate_echo_servers calc_echo_servers validate);

sub allocate_echo_servers {
    my ($sites, $echo_servers) = @_;

    # validate the arguments
    unless(defined $sites and ref($sites) eq 'HASH') {
        carp "Invalid site-endpoint map data - need a hash_ref having list of end points for each site";
        return undef;
    }
    unless(defined $echo_servers and ref($echo_servers) eq 'ARRAY') {
        carp "Invalid Echo server list - need an array_ref having list of available echo servers";
        return undef;
    }

    my @available_echo_hosts = sort(@{$echo_servers}); # sort the echo server list to make sure each site claims echo servers in same order
    my %end_points = (); # store the list of sites an end point is part of
    my %site_details = (); # store list of end points a site has and list of available echo servers
    my %used_echo_hosts = ();

    # sort sites by the number of end points they have
    my @site_list=sort { scalar(@{$sites->{$b}}) <=> scalar(@{$sites->{$a}}) } keys(%$sites);

    # initialize the data structures required for allocation
    foreach my $site (@site_list) {
        foreach my $end_point (@{$sites->{$site}}) {
            push(@{$end_points{$end_point}{'sites'}}, $site);
        }
        $site_details{$site}{'end_points'} = [ sort(@{$sites->{$site}}) ];
        $site_details{$site}{'available_echo_hosts'} = [ @available_echo_hosts ];
    }

    # do the allocations
    foreach my $site (@site_list) {
        foreach my $end_point ( @{$site_details{$site}{'end_points'}} ) {
            my @es = @{$site_details{$site}{'available_echo_hosts'}};
            my $allocated = undef;
            foreach my $e (@es) {
                # Check for conflicts
                my $conflicts=0;
                foreach my $o (@{$end_points{$end_point}{'sites'}}) {
                    my $found = grep { $_ eq $e } @{$site_details{$o}{'available_echo_hosts'}};
                    unless($found) {
                        # conflict found
                        $conflicts=1;
                        last;
                    }
                }
                next if( $conflicts );
                $allocated=1;
                $end_points{$end_point}{'echo_server'} = $e;
                $used_echo_hosts{$e} = 1;
                foreach my $o_having_ep ( @{$end_points{$end_point}{'sites'}} ) {
                    # remove the endpoint and the allocated echo server from all sites
                    $site_details{$o_having_ep}{'end_points'} = [ grep { $_ ne $end_point } @{$site_details{$o_having_ep}{'end_points'}} ];
                    $site_details{$o_having_ep}{'available_echo_hosts'} = [ grep { $_ ne $e } @{$site_details{$o_having_ep}{'available_echo_hosts'}} ];
                }
                last;
            }
            unless($allocated) {
                carp "Unable to allocate an echo server for $end_point. May need more echo servers\n";
                return undef;
            }
        }
    }

    my %dnsmap = ();
    while( my ($origin, $v) = each(%end_points)) {
        $dnsmap{$origin} = $v->{'echo_server'};
    }
    
    unless(validate($sites,\%dnsmap)) {
        warn "Invalid allocation of echo servers.";
        return undef;
    }
    return \%dnsmap;
}

sub calc_echo_servers {
    my ($sites) = @_;

    # get the list of origin servers across all sites
    my %origin = ();
    while( my ($site,$origins) = each(%$sites) ) {
        foreach my $o (@$origins) {
            $origin{$o} = 1;
        }
    }
    my $total_origins = scalar(keys(%origin));
    # create as many dummy echo server names as total origin servers
    my @echo_servers = map { "echo-$_" } 1..$total_origins;

    # do a dummy allocation
    my $alloc = allocate_echo_servers($sites, \@echo_servers);
    unless($alloc) {
        carp "Error calculating number of echo servers required";
        return undef;
    }

    # get the number of echo servers used
    my %echo_used = ();
    while (my ($k,$v) = each(%$alloc)) {
        $echo_used{$v} = 1;
    }
    return scalar(keys(%echo_used));
}

sub validate {
    my ($sites, $ep_map) = @_;
    foreach my $o (keys(%$sites)) {
        my %used = ();
        foreach my $ep (@{$sites->{$o}}) {
            my $echo_server =  $ep_map->{$ep};
            if($used{$echo_server}) {
                warn "Conflicting assignment identified for site $o. $used{$echo_server} and $ep are assigned to $echo_server.\n";
                return undef;
            }
            $used{$echo_server} = $ep;
        }
    }
    return 1;
}

1;

__END__

=head1 NAME

Echo::DnsMapper - Generate DNS mappings to map Origin servers to Echo servers

=head1 SYNOPSIS

    use Echo::DnsMapper qw(calc_echo_servers allocate_echo_servers validate);
    # Site-Origin mapping
    my $sites = {
        # Site => [ list of origins ]
        'foo1.site.com' => [ qw(origin1.site.com origin2.site.com) ],
        'foo2.site.com' => [ qw(origin2.site.com origin3.site.com) ],
    };
    # List of echo servers
    my $echo_servers = [ qw(echo1 echo2 echo3) ];

    # assign echo servers to origin servers
    my $alloc = allocate_echo_servers($sites, $echo_servers);

    # find out number of echo servers required
    my $num_servers = calc_echo_servers($sites);

    # validate echo server allocation to see if there is any conflict
    my $valid = validate($sites, $alloc);
    unless($valid) {
        print STDERR "Echo server allocation failed";
    }

=head1 DESCRIPTION

This module is used to generate dns maps for mapping origin servers to
echo servers. A Site that is fronted by a proxy can be served by more than
one origin server depending on the url,client etc. It is also possible
that the same origin server serving for multiple sites, for eg. shared
static content server. When a single proxy fronts multiple websites there
is a possibility of having lots of origin servers to which it may proxy
the traffic to. This module tries to use minimum number of echo servers
while avoiding conflict. The module provides functions to do echo
server allocation, calculate the number of echo servers required to
do a non-cnflicting assignment of echo servers and to validate echo
server allocation.

=head2 Functions

=over 8

=item allocate_echo_servers($site_origin_map, $echo_server_list)

This function assigns echo servers to origins. On success it returns
a hash mapping an origin server to its corresponding echo server. On
failure it returns undef. The function usually fails when enough number
of echo servers are not available. The function needs two arguments:
a hash ref to site-origin mapping and array ref to list of available
echo servers. The site-origin map is a hash mapping website to the list
of possible origin servers from which content for it can be served.

=item calc_echo_servers($site_origin_map)

This function calcultes the number of echo servers that will required
to do a successful mapping. This requires site-origin map as argument.

=item validate($site_origin_map, $allocation)

This function validates that the allocation made for a give site-origin
map is valid i.e. there are no conflicting assignments made. It needs
the site-origin map hashref and hashref containing map of origin server
to echo server. If the mapping is invalid it returns undef else returns 1.

=back

=cut
