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
package Echo::Config::EntityFactory;
use strict;
use warnings;
use Log::Log4perl;

sub new {
    my ($class) = @_;
    my $self = {};
    $self->{'entity_classes'} = {
        'templates' => 'Echo::Config::Template',
        'macros' => 'Echo::Config::Macro',
        'hosts' => 'Echo::Config::Host',
        'dnsmaps' => 'Echo::Config::Dnsmap',
    };
    $self->{'__logger'} = Log::Log4perl::get_logger();
    bless($self, $class);
    return $self;
}

sub supports {
    my ($self, $type) = @_;
    return $self->{'entity_classes'}{$type};
}

sub get_entity {
    my ($self, $type, $name, $def, $cfg, $source) = @_;
    my $eclass = $self->{'entity_classes'}{$type};
    unless($eclass) {
        $self->{'__logger'}->error("Unknown entity type $type");
        return undef;
    }

    my $entity_obj;
    eval qq[
        use $eclass;
        \$entity_obj = ${eclass}->new(\$name,\$def,\$cfg,\$source);
    ];
    if($@) {
        $self->{'__logger'}->error("Error creating entity $name of type $type from $source: $@");
        return undef;
    }
    return $entity_obj;
}

1;


__END__

=head1 NAME

Echo::Config::EntityFactory - Entity Factory object

=head1 DESCRIPTION

Creates and returns the appropriate entity object depending on the entity type.

=head1 AUTHOR

Damodharan Rajalingam (damu@yahoo-inc.com)

=cut
