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

package Echo::TestAction;
use Carp;

use strict;
use warnings;

sub new {
    my ($class,$action_def) = @_;
    my $self = {};

    bless($self,$class);
    return $self;
}

sub run {
    warn "This method needs to be implemented by the child class";
    return undef;
}

1;


__END__

=head1 NAME

Echo::TestAction - Base Class for Test Actions

=head1 DESCRIPTION

This is base class for Test Actions. Test Action implementations should
inherit this class and implement the run method which will be called
when executing the test action.

=head1 AUTHOR

Damodharan Rajalingam (damu@yahoo-inc.com)

=cut
