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
