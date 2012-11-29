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
package Echo::Config::Template;
use base qw(Echo::Config::Entity Echo::Config::MacroContainer);
use strict;
use warnings;
use Clone qw(clone);

sub get_vars {
    my ($self) = @_;
    if($self->{'__def'}{'vars'}) {
        return clone($self->{'__def'}{'vars'});
    }
    return undef;
}

sub get_test_defs {
    my ($self) = @_;
    unless($self->{'__macros_expanded'}) {
        $self->__expand_macros();
        $self->{'__macros_expanded'} = 1;
        delete $self->{'__def'}{'test_macros'};
    }
    if(exists $self->{'__def'}{'tests'}) {
        return @{clone($self->{'__def'}{'tests'})};
    }
    return undef;
}

sub is_global {
    my ($self) = @_;
    return ($self->{'__def'}{'global_template'} and lc($self->{'__def'}{'global_template'}) eq 'yes') ? 'yes' : undef;
}

1;

__END__

=head1 NAME

Echo::Config::Template - Template config object 

=head1 DESCRIPTION

Object to hold template definition

=head1 AUTHOR

Damodharan Rajalingam (damu@yahoo-inc.com)

=cut
