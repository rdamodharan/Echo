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
