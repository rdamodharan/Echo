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
