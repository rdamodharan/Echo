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

package Echo::Test;
use strict;
use warnings;
use Echo::TestActionFactory;
use Echo::Utils;
use Log::Log4perl;
use Clone qw(clone);
use Data::Dumper;

sub new {
    my ($class, $test_def, $phost) = @_;
    my $self = {};
    $self->{'__def'} = $test_def;
    $self->{'__logger'} = Log::Log4perl::get_logger();
    $self->{'__parent'} = $phost; # parent host entity having the test definition
    $self->{'__location'} = $phost->location() . "/[tests]";
    $test_def->{'test_sequence'} ||= [];
    bless($self, $class);
    return $self;
}

sub run {
    my ($self, $site, $server) = @_;
    my $successful_actions=0;
    my $failed_actions=0;
    my $total=0;
    
    my $test_vars = {
        'test:site' => $site, # the site that is being tested
        'test:server' => $server, # the server that is being tested
    };
    my @actions = $self->__get_actions($test_vars);
    foreach my $action (@actions) {
        my $status = $action->run($site, $server);
        if($status) {
            $successful_actions++;
        } else {
            $failed_actions++;
        }
        $total++;
    }
    $self->{'__logger'}->info("Total actions in test: $total, successful: $successful_actions, failed: $failed_actions");
    if(wantarray) {
        return ($total, $successful_actions, $failed_actions);
    }
    return ($failed_actions > 0) ? undef : 1;
}

sub name {
    my ($self) = @_;
    return $self->{'__def'}{'name'};
}

sub location {
    my ($self) = @_;
    return $self->{'__location'};
}

sub get_dnsmap {
    my ($self, $origin) = @_;
    return $self->{'__parent'}->get_dnsmap($origin);
}

sub __get_actions {
    my ($self, $test_vars) = @_;
    my $test_def = $self->{'__def'};
    $test_def->{'test_sequence'} ||= [];
    my @actions_def = @{Echo::Utils::interpolate_vars_in_ds(clone($test_def->{'test_sequence'}), $test_vars)};
    my @actions = ();
    my $action_factory = Echo::TestActionFactory->new();
    foreach my $action_def (@actions_def) {
        my $action_obj = $action_factory->get_test_action_object($action_def, $self);
        unless($action_obj) {
            $self->{'__logger'}->error("Unable to initialize action " . $action_def->{'action'});
            next;
        }
        push(@actions, $action_obj);
    }
    return @actions;
}

1;

__END__

=head1 NAME

Echo::Test - Echo Test Object 

=head1 DESCRIPTION

Test object which holds the test definition which is a sequence of TestActions.

=head1 AUTHOR

Damodharan Rajalingam (damu@yahoo-inc.com)

=cut
