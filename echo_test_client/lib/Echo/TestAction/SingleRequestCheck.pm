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
package Echo::TestAction::SingleRequestCheck;
use strict;
use warnings;
use base qw(Echo::TestAction);
use LWP::UserAgent;
use Log::Log4perl;
use Data::Dumper;

sub new {
    my ($class, $def, $ptest) = @_;
    
    return undef unless($def);
    
    my $self = {
        '__location' => '',
        '__parent' => $ptest,
        '__logger' => Log::Log4perl::get_logger(),
    };
    
    my $action_def = {};
    $action_def->{'request_info'} = $def->{'request_info'};
    $action_def->{'request_info'}{'method'} ||= 'GET';
    $action_def->{'request_info'}{'path'} ||= '/';
    $action_def->{'reply_type'} ||= 'echo_reply';
    $action_def->{'validate'} = $def->{'validate'} || [];

    $self->{'__def'} = $action_def;
   
    bless($self, $class);
    return $self;
}

sub run {
    my ($self, $site, $proxy_server) = @_;
    my $logger = $self->{'__logger'};
    my $ua = LWP::UserAgent->new();
    $ua->default_header('Host' => $site);
    my $def = $self->{'__def'};
    $ua->max_redirect($def->{'request_info'}{'max_redirect'} || 0);
    if(exists $def->{'request_info'}{'add_headers'}) {
        while(my ($hdr, $val) = each(%{$def->{'request_info'}})) {
            $logger->debug("Adding header $hdr: $val");
            $ua->default_header($hdr => $val);
        }
    }
    my $url = qq(http://$proxy_server) . $def->{'request_info'}{'path'};
    my $resp = $ua->get($url);
    $logger->info("Sending request to $url (Site: $site)...");
    my $response_vars = {};
    $response_vars->{'response_code'} = $resp->code;
    ( $response_vars->{'response_code_category'} = $resp->code ) =~ s/(\d)\d\d/$1xx/;
    $response_vars->{'status_message'} = $resp->message;
    $response_vars->{'status_line'} = $resp->status_line;
    $response_vars->{'content'} = $resp->content;
    $response_vars->{'decoded_content'} = $resp->decoded_content;
    foreach my $hdr ($resp->header_field_names) {
        $response_vars->{"header:$hdr"} = $resp->header($hdr);
    }
    if($resp->header('echo_server_ip')) {
        # Process the echo server reply which is the actual request sent by proxy
        $response_vars->{'origin'} = $resp->header('echo_server_ip');
        _parse_echo_reply($resp->decoded_content, $response_vars);
    }
#    print Dumper($response_vars);
    my $result = $self->_validate($response_vars);
    return $result;
}

sub _validate {
    my ($self, $response_vars) = @_;
    my @errors = ();
    my $logger = $self->{'__logger'};
    my %ops = (
            'eq' => sub { my $a = $_[0] || ''; my $b = $_[1] || ''; return  $a eq $b },
            'ne' => sub { my $a = $_[0] || ''; my $b = $_[1] || ''; return  $a ne $b },
            'gt' => sub { my $a = $_[0] || ''; my $b = $_[1] || ''; return  $a > $b  },
            'lt' => sub { my $a = $_[0] || ''; my $b = $_[1] || ''; return  $a < $b  },
            'ge' => sub { my $a = $_[0] || ''; my $b = $_[1] || ''; return  $a >= $b },
            'le' => sub { my $a = $_[0] || ''; my $b = $_[1] || ''; return  $a <= $b },
            'exists' => sub { return defined($_[0]); },
            'not_exists' => sub { return not defined($_[0]); },
            'regex_match' => sub { my $a = $_[0] || ''; my $b = $_[1] || ''; my $r = qr/$b/; return $a =~ $r },
            'regex_nomatch' => sub { my $a = $_[0] || ''; my $b = $_[1] || ''; my $r = qr/$b/; return $a !~ $r },
            );
    my ($total, $success, $failed) = (0,0,0);
    foreach my $v (@{$self->{'__def'}{'validate'}}) {
        $total++;
        my ($condvar, $op, $value) = @$v;
        my $condition = "$condvar $op $value";
        unless(exists $ops{$op}) {
            $logger->error("Unknown op $op specified in [$condition]");
            push(@errors, { condition => $condition, error => "Unknown op $op specified in [$condition]"});
            $failed++;
            next;
        }
        unless($condvar) {
            $failed++;
            $logger->error("No condvar specified in condition");
            next;
        }
       
        if($condvar eq 'origin') {
            my $dnsmap = $self->{'__parent'}->get_dnsmap($value);
            unless($dnsmap) {
                $logger->error("Unable to find the echo server mapped to $value");
                $failed++;
                next;
            }
            my $echo_server_ip = $dnsmap->echo_server_ip();
            $logger->info("Replacing origin:$value with the ip of echo-server($echo_server_ip) mapped to it");
            $value = $echo_server_ip;
        }
        if ($ops{$op}->($response_vars->{$condvar}, $value)) {
            $logger->info("[$condition] succeeded");
            $success++;
        } else {
            $logger->error("[$condition] failed");
            $logger->error("$condvar value is '" . ($response_vars->{$condvar} || '') . "'");
            $failed++;
        }
    }
    $logger->info("Total validations: $total, success: $success, failed: $failed");
    return $failed>0 ? undef : 1;
}

sub _parse_echo_reply {
    my ($reply, $vhash) = @_;
    my $preq = HTTP::Request->parse($reply);
    return undef unless ($preq->method and $preq->uri);
    $vhash->{'proxy_request_method'} = $preq->method;
    $vhash->{'proxy_request_protocol'} = $preq->protocol;
    $vhash->{'proxy_request_url'} = $preq->uri;
    foreach my $hdr ($preq->header_field_names) {
        $vhash->{"proxy_request_header:$hdr"} = $preq->header($hdr);
    }
    return $vhash;
}

1;

__END__

=head1 NAME

Echo::TestAction::SingleRequestCheck - Single Request Check Test Action 

=head1 DESCRIPTION

This test action can be used to fire a single request to the the proxy
server and validate some conditions on the proxy request and the reply.

=head1 AUTHORS

Damodharan Rajalingam (damu@yahoo-inc.com), Pushkar Sachdev (psachdev@yahoo-inc.com)

=cut
