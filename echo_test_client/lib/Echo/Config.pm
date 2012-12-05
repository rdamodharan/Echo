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

package Echo::Config;
use strict;
use warnings;
use YAML::Syck;
use Carp;
use Log::Log4perl;
use Clone qw(clone);
use Echo::Test;
use Echo::Utils;
use Echo::Config::EntityFactory;
use Socket;
use Data::Dumper;

sub new {
    my $class = shift;
    my $self = {
        'global_templates' => [],
        'templates' => {},
        'hosts' => {},
        'macros' => {},
    };
    $self->{'__entity_factory'} = Echo::Config::EntityFactory->new();
    $self->{'__logger'} = Log::Log4perl::get_logger();
    bless($self, $class);
    return $self;
}

sub add_config_file {
    my ($self,$file) = @_;
    croak "Unable to read $file"  unless (-r $file);
    my $_config = YAML::Syck::LoadFile($file);
    croak "Unable to load $file" unless(defined $_config);

    my $efactory = $self->{'__entity_factory'};
    my $logger = $self->{'__logger'};
    while(my ($entity_section, $entities) = each(%$_config)) {
        unless($efactory->supports($entity_section)) {
            $logger->error("Unknown section $entity_section in file $file");
            next;
        }
        while( my ($entity_name, $entity_def) = each(%$entities) ) {
            my $entity_source = "[$file]/[$entity_section]";
            my $entity = $efactory->get_entity($entity_section, 
                                               $entity_name, 
                                               $entity_def,
                                               $self,
                                               $entity_source);
            unless($entity) {
                $self->{'__logger'}->error("Unable to create $entity_source/[$entity_name]");
                next;
            }
            $self->{$entity_section}{$entity_name} = $entity;
        }
    }

    while( my ($t, $t_obj) = each(%{$self->{'templates'}}) ) {
        push(@{$self->{'global_templates'}}, $t) if ($t_obj->is_global());
    }
}

sub get_host_list {
    my ($self) = @_;
    return keys(%{$self->{'hosts'}}) ;
}

sub get_macro_list {
    my ($self) = @_;
    return keys(%{$self->{'macros'}});
}

sub get_template_list {
    my ($self) = @_;
    return keys(%{$self->{'templates'}});
}

sub get_macro {
    my ($self, $m) = @_;
    return $self->{'macros'}{$m};
}

sub get_template {
    my ($self, $t) = @_;
    return $self->{'templates'}{$t};
}

sub get_host {
    my ($self, $h) = @_;
    return $self->{'hosts'}{$h};
}

sub get_dnsmap {
    my ($self,$origin) = @_;
    return $self->{'dnsmaps'}{$origin};
}

sub get_global_template_list {
    my ($self) = @_;
    return @{$self->{'global_templates'}};
}

#
# Private functions
#

1;

__END__

=head1 NAME

Echo::Config - Echo Test Client Config Object 

=head1 DESCRIPTION

Hold the configuration information for the test client. The config can
be spanning multiple files and they can be added using the add_config_file
method. It also provides accessors to get the config elements.

=head2 Functions

=over 8

=item B<add_config_file($file)>

Add the configuration from the file

=item B<get_host_list()>

Get the list of hosts for which tests have been configured

=item B<get_macro_list>

Get the list macros defined

=item B<get_template_list>

Get the list of templates

=item B<get_macro($macro_name)>

Get the macro definition. Returns undef if the macro is not defined in any of the config file loaded

=item B<get_template($template_name)>

Get the template definition. Returns undef if template is not defined in any of the config file loaded

=item B<get_host($host)>

Get the test definition for the given host. Returns undef if template is not defined in any of the config file loaded

=item B<get_dnsmap()>

Get the dnsmap entry for the given server.  Returns undef if dnsmap entry for the server is not defined in any of the config file loaded

=item B<get_global_template_list()>

Get the list of templates that should be included for all hosts

=back

=head1 AUTHOR

Damodharan Rajalingam (damu@yahoo-inc.com)

=cut
