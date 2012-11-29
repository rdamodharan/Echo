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

package Echo::TestActionFactory;
use strict;
use warnings;
use Log::Log4perl;

sub new {
    my ($class, $parent) = @_;
    my $self = {
        'parent' => $parent,
        'action_classes' => {
            'sleep' => 'Echo::TestAction::Sleep',
            'single_request_check' => 'Echo::TestAction::SingleRequestCheck',
        }
    };
    bless($self, $class);
    return $self;
}

sub get_test_action_object {
    my ($self, $action_def, $ptest) = @_;
    my $logger = Log::Log4perl::get_logger();
    my $action_type = $action_def->{'action'};
    my $action_class = $self->{'action_classes'}{$action_type};
    unless($action_class) {
        $logger->error("Unknown action type $action_type");
        return undef;
    }
    my $obj;
    eval qq{
        use $action_class;
        \$obj = $action_class->new(\$action_def, \$ptest);
    };
    if ($@) {
        $logger->error("Unable to create test action object: $@");
    }
    return $obj;
}
1;

__END__

=head1 NAME

Echo::TestActionFactory - Factory class to produce appropriate TestAction 

=head1 DESCRIPTION

This is factory object to get appropriate TestAction objects depending on the action type defined in the test sequence.

=head1 AUTHOR

Damodharan Rajalingam (damu@yahoo-inc.com)

=cut
