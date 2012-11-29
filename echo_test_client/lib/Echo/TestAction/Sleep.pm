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
package Echo::TestAction::Sleep;
use strict;
use warnings;
use base qw(Echo::TestAction);
use Time::HiRes qw(usleep);
use Log::Log4perl;
sub new {
    my ($class, $action_def,$ptest) = @_;
    my $logger = Log::Log4perl::get_logger();
    unless($action_def->{'duration'}) {
        $logger->error("No duration specified");
        return undef;
    }
    my $self = {
        '__def' => { 'duration' => $action_def->{'duration'} },
        '__logger' => $logger,
        '__parent' => $ptest,
    };
    bless($self,$class);
    return $self;
}

sub run {
    my ($self) = @_;
    my $duration = $self->{'__def'}{'duration'};
    $self->{'__logger'}->info("Sleeping for $duration milliseconds\n");
    usleep($duration * 1000);
    return 1;
}

1;

__END__

=head1 NAME

Echo::TestAction::Sleep - Sleep Action 

=head1 DESCRIPTION

Sleep for specified number of milliseconds

=head1 AUTHOR

Damodharan Rajalingam (damu@yahoo-inc.com)

=cut
