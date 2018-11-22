## api_isc-dhcp

### Service URLs

* API: http://IP:88/
* API-Documentation: http://IP:88/readme
* Simple DHCP frontend: http://IP:88/dhcp


### api.service Systemd Definition:

    [Unit]
    Description=api.pl
    After=syslog.target network.target remote-fs.target nss-lookup.target
     
    [Service]
    WorkingDirectory=/api_isc-dhcp
     
    ExecStart=/bin/sh -c "/api_isc-dhcp/api.pl 88 >> /api_isc-dhcp.log 2>&1"
     
    Type=simple
    Restart=on-failure
     
     
    [Install]
    WantedBy=multi-user.target


### Perl Dependencies:
 - HTTP-Server-Simple-CGI-PreFork   (requires IPv6 and debian packages 'libssl-dev' & 'libz-dev' to compile)
 - Net::ISC::DHCPd
 - JSON
 - *______ below should be installed by previous automatically ______*
 - Class::Load
 - File::Temp
 - IO::Pty
 - Moose
 - MooseX::Types
 - MooseX::Types::Path::Class
 - NetAddr::IP
 - Path::Class
 - Time::HiRes
 - Time::Local
 - HTTP::Server::Simple
 - IO::Socket::INET6
 - Net::Server
 - Net::Server::PreFork
 - Net::Server::Proto::SSLEAY
 - Net::Server::Single
 - Net::SSLeay
 - Socket6
 - *. . . and possibly others . . .*
