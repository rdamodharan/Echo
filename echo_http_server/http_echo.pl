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
use strict;
use warnings;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Getopt::Long;
use Socket;
use POSIX;

my %opts = (
        'listen' => [],
        'verbose' => 0,
        );

my $HTTP_HEADER=<<HTTP
HTTP/1.1 200 OK
Content-Type: text/plain
Cache-Control: private
ECHO-SERVER-IP: %s
ECHO-SERVER-PORT: %d
ECHO-SERVER: %s:%d

HTTP
;

GetOptions(
    'user|u=s' => \$opts{'user'},
    'listen|l=s@' => $opts{'listen'},
    'help|h' => sub { print_usage(); exit 0 },
    'verbose|v' => \$opts{'verbose'},
);

my $stdout = new AnyEvent::Handle(
    fh => \*STDOUT, 
    on_error => sub { warn "Error $_[2]\n"; $_[0]->destroy },
    on_eof => sub { $_[0]->destroy }
);
my $stderr = new AnyEvent::Handle(
    fh => \*STDERR, 
    on_error => sub { warn "Error $_[2]\n"; $_[0]->destroy },
    on_eof => sub { $_[0]->destroy } 
);

my @listen = @{$opts{'listen'}};

unless(@listen) {
    log_err("No listen addresses specified");
    print_usage();
    exit 2;
}

foreach my $addr (@listen) {
    my ($l_addr,$l_port) = split(/:/,$addr,2);
    $l_addr ||= undef;
    $l_port ||= 80;
    log_msg(0, "Listening on " . ($l_addr || '*') . ":$l_port");
    tcp_server($l_addr, $l_port , sub {
            my ($fh, $host, $port)=@_;
            my $handle;
            my $_s_addr = getsockname($fh);
            my ($_l_port, $_l_addr) = AnyEvent::Socket::unpack_sockaddr($_s_addr);
            my $_l_addr_str = AnyEvent::Socket::ntoa($_l_addr);
            log_msg(0,"Connection from ${host}:${port} to ${_l_addr_str}:${_l_port}");
            $handle = new AnyEvent::Handle
                fh => $fh,
                on_error => sub { log_err("${host}:${port} :: $_[2]\n"); $_[0]->destroy },
                on_eof => sub { $handle->destroy };

            $handle->push_read( regex => qr/\015\012\015\012/,undef,undef, sub {
                    my ($handle,$data) = @_;
                    $handle->push_write(sprintf($HTTP_HEADER,$_l_addr_str, $_l_port, $_l_addr_str, $_l_port));
                    $handle->push_write($data);
                    $handle->on_drain( sub {shutdown $_[0]{fh}, 2; close($_[0]{fh});$handle->destroy});
                } );
        }, undef);
}


if($opts{'user'}) {
    my $new_uid = getpwnam($opts{'user'});
    die "Unable to find user $opts{'user'}\n" unless($new_uid);
    die "Unable to change uid to $opts{'user'}: $!" unless(POSIX::setuid($new_uid));
    log_msg(0,"Dropping privileges to $opts{'user'}");
}

my $cv = AnyEvent->condvar;

$cv->recv;

#
# End of main
#
sub log_msg {
    my ($level, $msg) = @_;
    $stdout->push_write("$msg\n") if($opts{'verbose'} >= $level);
}

sub log_err {
    my ($msg) = @_;
    $stderr->push_write("ERROR> $msg\n");
}

sub print_usage {
    print <<USAGE
Usage: $0 --listen|l=<host>:<port> [--listen|l=<host2>:<port2> ...] [--user|-u=user_to_run_as] [--verbose|-v] 
       $0 [--help|h]
USAGE
}

