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
