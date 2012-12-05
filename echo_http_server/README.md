# ECHO HTTP Server

This is a simple socket server which can be used to capture HTTP
requests. This is a core component used in ECHO Proxy Server testing
framework. Point a client to the Echo server and do a HTTP request
the reply will be the HTTP request received by the echo server. This is
helpful to know the actual request and can be used for testing.

## Example

    $ http_echo.pl --listen :9101
    $ curl localhost:9101
    GET / HTTP/1.1
    User-Agent: curl/7.15.5 (x86_64-redhat-linux-gnu) libcurl/7.15.5
    OpenSSL/0.9.8b zlib/1.2.3 libidn/0.6.5
    Host: localhost:9101
    Accept: */*
                
## License    

This software is licensed under the Artistic license. Please refer the
LICENSE.txt.
