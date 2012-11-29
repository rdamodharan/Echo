# Echo
Echo is a framework for testing HTTP proxy server remap rules. There
are 3 components in this framework:

1. _HTTP Echo Server_ - This is used for capturing the requests made by the
proxy server. echo_http_server provides an echo server to capture http
requests 

1. _Mock DNS Server_ - This intercepts the dns requests for resolving origin
server IPs and maps them to one of the HTTP Echo Servers. Open source dns
servers like dnsmasq, PowerDNS etc can be used for this. echo_dns_mapper
provides a script to create the origin to echo server mapping which can
be used to generate the configuration for the dns server chosen as mock
dns server.

1. _Echo Test Client_ - This is the actual test client which makes
requests to the proxy server and validates the remap rule based
on the response. It accept one or more test spec files written
in YAML. echo_test_client has the test client script.

The test framework is written in Perl and requires the following packages:
*  LWP
*  HTTP::Message
*  Log4perl
*  AnyEvent
*  Clone
*  List::MoreUtils
*  Pod::Usage
*  Text::TabularDisplay
*  YAML
*  YAML::Syck

## License

Refer to [LICENSE.txt](./Echo/blob/master/LICENSE.txt "LICENSE.txt")

## Authors

*  Damodharan Rajalingam (damu@)
*  Soumya Deb (soumyad@)
*  Pushkar Sachdeva (psachdev@)

(E-mail domain is yahoo-inc.com)
