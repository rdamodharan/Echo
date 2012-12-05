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

package Echo::Config::Entity;
use strict;
use warnings;
use Log::Log4perl;

sub new {
    my ($class, $name, $def, $cfg, $source) = @_;
    my $self = {};
    $self->{'__name'} = $name;
    $self->{'__source'} = $source;
    $self->{'__location'} = "$source/[$name]";
    $self->{'__config'} = $cfg; # parent config entity
    $self->{'__logger'} = Log::Log4perl::get_logger();
    $self->{'__def'} = $def;
    bless($self, $class);
    return $self;
}

sub source {
    my ($self) = @_;
    return $self->{'__source'};
}

sub entity_type {
    my ($self) = @_;
    my $class = ref($self);
    my $entity = (split(/::/, $class))[-1];
    return lc($entity);
}

sub name {
    my ($self) = @_;
    return $self->{'__name'};
}

sub location {
    my ($self) = @_;
    return $self->{'__location'};
}

# exposing some of parent config's methods to get entities
sub get_dnsmap {
    my ($self,$origin) = @_;
    return $self->{'__config'}->get_dnsmap($origin);
}

1;

__END__

=head1 NAME

Echo::Config::Entity - Entity base class 

=head1 DESCRIPTION

Base class that all config  entity objects like Host, Template etc should be inheriting from

=head1 AUTHOR

Damodharan Rajalingam (damu@yahoo-inc.com)

=cut
