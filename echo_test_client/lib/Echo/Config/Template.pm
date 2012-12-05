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
