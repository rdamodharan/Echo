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
#===============================================================================
package Echo::Config::MacroContainer;

use strict;
use warnings;

sub __expand_macros {
    my ($self) = @_;
    my $def = $self->{'__def'};
    my $logger = $self->{'__logger'};
    my $location =  $self->{'__location'} . "/[test_macros]";

    unless(exists $def->{'test_macros'}) {
        $self->{'__macros_expanded'} = 1;
        return;
    }

    if(ref($def->{'test_macros'}) eq 'HASH') {
        return $self->__expand_macros_hash();
    } elsif(ref($def->{'test_macros'}) eq 'ARRAY') {
        return $self->__expand_macros_list();
    } else {
        $self->{'__logger'}->error("Invalid macro call format in $location");
        return undef;
    }
    return $self;
}

sub __expand_macros_list {
    my ($self) = @_;
    my $def = $self->{'__def'};
    my $cfg = $self->{'__config'};
    my $logger = $self->{'__logger'};
    my $location =  $self->{'__location'} . "/[test_macros]";
    $def->{'tests'} ||= [];
    $logger->debug("Expanding macros in $location: $location");
    foreach my $_mcall (@{$def->{'test_macros'}}) {
        my $macro_name = shift(@$_mcall);
        my $test = $self->__expand_macro_call($macro_name, $_mcall);
        next unless($test);
        push(@{$def->{'tests'}}, $test);
    }
    return $self;
}

sub __expand_macros_hash {
    my ($self) = @_;
    my $def = $self->{'__def'};
    my $cfg = $self->{'__config'};
    my $logger = $self->{'__logger'};
    my $location =  $self->{'__location'} . "/[test_macros]";
    $def->{'tests'} ||= [];
    while( my ($macro_name, $macro_calls) = each(%{$def->{'test_macros'}}) ) {
        foreach my $_mcall (@$macro_calls) {
            my $test = $self->__expand_macro_call($macro_name, $_mcall);
            next unless($test);
            push(@{$def->{'tests'}}, $test);
        }
    }
    return $self;
}

sub __expand_macro_call {
    my ($self, $macro_name, $_mcall) = @_;
    my $cfg = $self->{'__config'};
    my $logger = $self->{'__logger'};
    my $location =  $self->{'__location'} . "/[test_macros]";
    my @mcall = @$_mcall;
    my $macro = $cfg->get_macro($macro_name);
    unless($macro) {
        $logger->error("Unable to find macro $macro_name used in $location");
        return undef;
    }
    my $test = $macro->expand(\@mcall, $location);
    unless($test) {
        $logger->error("Expansion of macro $macro_name failed in $location");
        return undef;
    }
    return $test;
}
1;

__END__

=head1 NAME

Echo::Config::MacroContainer - Base class for entities that can have macros 

=head1 DESCRIPTION

Template and Host objects which can have macro definition inherit
this class. This class has methods to expand macro definitions to test
definitions

=head1 AUTHOR

Damodharan Rajalingam (damu@yahoo-inc.com)

=cut
