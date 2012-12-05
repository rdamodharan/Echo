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

package Echo::Utils;
use strict;
use warnings;
use List::MoreUtils qw(uniq);
use Log::Log4perl;
use Socket;
use Exporter qw(import);

our @EXPORT_OK = qw(
                    interpolate_vars_in_ds
                    get_ip_addr
                   );

our $logger = Log::Log4perl::get_logger();

sub interpolate_vars_in_ds{
    my ($ds, $vars) = @_;
    my $type = ref($ds);
    unless($type) {
        # scalar value
        return interpolate_vars_in_scalar($ds,$vars);
    }
    if($type eq 'SCALAR') {
        #ref to scalar
        my $_scalar = interpolate_vars_in_scalar($$ds, $vars);
        return \$_scalar;
    }
    if($type eq 'ARRAY') {
        # ref to array
        my $ds = [ map(interpolate_vars_in_ds($_, $vars), @$ds) ];
        return $ds;
    }
    if($type eq 'HASH') {
        # ref to hash
        foreach my $key (keys %$ds) {
            $ds->{$key} = interpolate_vars_in_ds($ds->{$key}, $vars);
        }
        return $ds;
    }
    return $ds;
}

sub interpolate_vars_in_scalar {
    my ($str, $vars) = @_;
    return $str unless($str);
    my @vars_in_str =  uniq( $str =~ m/(?<!\\)%{(.+?)}/g );
    foreach my $var (@vars_in_str) {
        next unless(exists $vars->{$var});
        $str =~ s/(?<!\\)\%\{$var\}/$vars->{$var}/g;
    }
    return $str;
}

sub get_ip_addr {
    my ($hostname) = @_;

    my $ip = gethostbyname($hostname);
    unless($ip) {
        $logger->error("Unable to resolve $hostname");
        return undef;
    }

    return inet_ntoa($ip);
}


1;

__END__

=head1 NAME

Echo::Utils - Package having common utility functions 

=head1 DESCRIPTION

Package having common utility functions

=head2 Functions

=over 8

=item B<get_ip_addr($hostname)>

Get the IP address of the given host

=item B<interpolate_vars_in_ds($ds_ref, $var_hash_ref)>

Interpolate the variable names inside the strings in the data
structure. The function recurses down the data structure (hashes and
arrays) and interpolates the variables in all strings it finds. It accepts
the reference to the data structure and a hash ref containing variable
names and their values. The variables are expressed as %{var_name}.

=back

=head1 AUTHOR

Damodharan Rajalingam (damu@yahoo-inc.com)

=cut
