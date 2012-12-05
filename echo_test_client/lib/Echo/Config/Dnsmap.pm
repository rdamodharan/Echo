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
package Echo::Config::Dnsmap;
use base qw(Echo::Config::Entity);

use strict;
use warnings;
use Echo::Utils qw(get_ip_addr);

sub new {
    my ($class, $name, $echo_server, $cfg, $source) = @_;
    my $self = {};
    $self->{'__name'} = $name;
    $self->{'__source'} = $source;
    $self->{'__location'} = "$source/[$name]";
    $self->{'__config'} = $cfg; # parent config entity
    $self->{'__logger'} = Log::Log4perl::get_logger();
    my $echo_server_ip = get_ip_addr($echo_server);
    unless($echo_server) {
        return undef;
    }
    $self->{'__def'} = {
        'echo_server' => $echo_server,
        'echo_server_ip' => $echo_server_ip,
    };
    bless($self, $class);
    return $self;
}

sub echo_server {
    my ($self) = @_;
    return $self->{'__def'}{'echo_server'};
}

sub echo_server_ip {
    my ($self) = @_;
    return $self->{'__def'}{'echo_server_ip'};
}
1;

__END__

=head1 NAME

Echo::Config::Dnsmap - Dnsmap Config Entity 

=head1 DESCRIPTION

Dnsmap Config Entity

=head1 AUTHOR

Damodharan Rajalingam (damu@yahoo-inc.com)

=cut
