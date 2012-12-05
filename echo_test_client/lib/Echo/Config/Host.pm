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

package Echo::Config::Host;
use strict;
use warnings;
use base qw(Echo::Config::Entity Echo::Config::MacroContainer);
use Echo::Test;
use Echo::Utils qw(interpolate_vars_in_ds);
use Clone qw(clone);
use Data::Dumper;

sub get_aliases {
    my ($self) = @_;
    return $self->{'__def'}{'alias'} ? @{$self->{'__def'}{'alias'}} : ();
}

sub run_tests_for_alias {
    my ($self, $alias, $server, $filter) = @_;
    return $self->__run_tests($alias, $server, $filter);
}

sub run_host_tests {
    my ($self, $server, $filter) = @_;
    return $self->__run_tests($self->name(), $server, $filter);
}
sub __run_tests {
    my ($self, $site, $server, $filter) = @_;
    my $logger = $self->{'__logger'};
    unless($self->{'__fully_realized'}) {
        $self->__fully_realize();
    }
    my ($success,$failed,$total) = (0,0,0);
    $logger->info("Running tests for [$site] against server [$server]");
    foreach my $test (@{$self->{'__def'}{'tests'}}) {
        my $rc = $test->run($site,$server);
        $total++;
        if($rc) {
            $success++;
        } else {
            $failed++;
        }
    }
    $logger->info("[$site] Total tests: $total, success: $success, failed: $failed");
    if(wantarray) {
        return ($total, $success, $failed);
    }
    return $failed>0 ? undef : 1;
}


#
# Private functions

sub __inherit_vars {
    my ($self) = @_;
    my $logger = $self->{'__logger'};
    my %used_templates = ();
    my $def = $self->{'__def'};
    my $cfg = $self->{'__config'};
    my %_vars = ();
    $logger->debug("Inheriting variables from templates");
    my @templates = ();
    push(@templates, $cfg->get_global_template_list());
    push(@templates, @{$def->{'template'}}) if $def->{'template'};
    foreach my $t (@templates) {
        next if exists $used_templates{$t}; 
        $logger->debug("Inheriting variables from template $t for " . $self->{'__location'});
        $used_templates{$t} = 1;
        my $t_obj = $cfg->get_template($t);
        unless($t_obj) {
            $logger->error("Unable to find template $t mentioned in " . $self->{'__location'} . "/[template]");
            next;
        }
        my $tvars = $t_obj->get_vars();
        while(my ($var, $val) = each(%$tvars)) {
            $_vars{$var} = $val;
        }
    }

    # merge the variables in to host
    while(my ($var, $val) = each(%_vars)) {
        next if $def->{'vars'}{$var};
        $def->{'vars'}{$var} = $val;
    }
    return $self;
}

sub __inherit_test_defs {
    my ($self) = @_;
    my $logger = $self->{'__logger'};
    my %used_templates = ();
    my $def = $self->{'__def'};
    my $cfg = $self->{'__config'};
    $def->{'tests'} ||= [];

    my %_vars = ();
    $logger->debug("Inheriting tests from templates");
    my @templates = ();
    # TODO: ability for a host to disable selected global templates
    push(@templates, $cfg->get_global_template_list());
    push(@templates, @{$def->{'template'}}) if $def->{'template'};
    foreach my $t (@templates) {
        next if exists $used_templates{$t}; 
        $logger->debug("Inheriting test definitions from template $t for " . $self->{'__location'});
        $used_templates{$t} = 1;
        my $t_obj = $cfg->get_template($t);
        unless($t_obj) {
            $logger->error("Unable to find template $t mentioned in " . $self->{'__location'} . "/[template]");
            next;
        }
        my @test_defs =  $t_obj->get_test_defs();
        push(@{$def->{'tests'}}, @test_defs) if (@test_defs);
    }

    return $self;
}

sub __instantiate_tests {
    my ($self) = @_;
    my $logger = $self->{'__logger'};
    my $def = $self->{'__def'};
    $logger->debug("Instantiating tests in " . $self->{'__location'});
    $def->{'tests'} ||= [];
    my @test_defs = @{$def->{'tests'}};
    $def->{'tests'} = [];

    foreach my $test (@test_defs) {
        next unless($test); # we have some 'undef's in list of tests :|
        my $test_obj = Echo::Test->new($test, $self);
        push(@{$def->{'tests'}}, $test_obj) if($test_obj);
    }
    return $self;
}

sub __fully_realize {
    my ($self) = @_;
    $self->__inherit_vars();
    $self->__expand_macros();
    $self->__inherit_test_defs();
    interpolate_vars_in_ds($self->{'__def'}{'tests'}, $self->{'__def'}{'vars'});
    
    $self->__instantiate_tests();
    $self->{'__fully_realized'} = 1;
    return $self;
}
1;

__END__

=head1 NAME

Echo::Config::Host - Host config object 

=head1 DESCRIPTION

Object that holds test configurations for a host

=head1 AUTHOR

Damodharan Rajalingam (damu@yahoo-inc.com)

=cut
