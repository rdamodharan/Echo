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
package Echo::Config::Macro;
use base qw(Echo::Config::Entity);

use strict;
use warnings;
use Echo::Utils qw(interpolate_vars_in_ds);
use Log::Log4perl;
use Clone qw(clone);

sub expand {
    my ($self, $_margs, $call_location) = @_;
    # Check for correct number of arguments
    my $macro_def = $self->{'__def'};
    my @margs= @$_margs;
    my $reqd_args = scalar(@{$macro_def->{'args'}});
    my $given_args = scalar(@margs);
    unless( $given_args == $reqd_args ) {
        $self->{'__logger'}->error(
                sprintf "Invalid number of arguments passed for Macro %s called from $call_location . Required: $reqd_args, Passed: $given_args",
                    $self->name()
                );
        return undef;
    }
    
    # Bind argument to argument names and push it vars hash of test
    my $test = clone($macro_def->{'test'});
    my $i=0;
    my $args = {};
    while( $i < $given_args ) {
        $args->{'arg:' . $macro_def->{'args'}[$i]} = $margs[$i];
        $i = $i + 1;
    }
    # interpolate arguments in the test actions
    interpolate_vars_in_ds($test,$args);
    return $test;
}

1;

__END__

=head1 NAME

Echo::Config::Macro - Macro config object 

=head1 DESCRIPTION

Object to hold macro definition

=head1 AUTHOR

Damodharan Rajalingam (damu@yahoo-inc.com)

=cut
