package API::methods::dhcp::service;

use strict; use warnings; use utf8; use feature ':5.10';


sub restart {
    my $cgi=shift; my $config=shift; my $params=shift;
    
    my $result = API::helpers::trim(`service isc-dhcp-server restart 2>&1`);
    return { 'rc' => 500, 'msg' => "error.dhcp.service.restart: ".$result }
        if( defined $result && $result ne "" );

    return undef;
}


1;