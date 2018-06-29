#!/usr/bin/perl
package API;

use strict; use warnings; use utf8; use feature ':5.10';

### Add our own path to %INC
use FindBin 1.51 qw( $RealBin );
use lib $RealBin;

### Load our helpers
use helpers;
### Load our server module
use server;


### SERVER OPTIONS
my $dev = (defined $ARGV[1] && $ARGV[1] eq 'dev') ? 1 : 0;
my %preforkOptions = (               # Options will be passed to Net::Server::PreFork
    prefork           => 1,          # Default: 0  -  Per default, prefork is turned off (e.g. server runs singlethreaded with Net::Server::Single instead of Net::Server::PreFork). This is very usefull for debugging and backward compatibility.
    min_servers       => $dev?1: 4,  # Default: 5  -  The minimum number of servers to keep running.
    min_spare_servers => $dev?1: 2,  # Default: 2  -  The minimum number of servers to have waiting for requests. Minimum and maximum numbers should not be set to close to each other or the server will fork and kill children too often.
    max_spare_servers => $dev?4: 10, # Default: 10 -  The maximum number of servers to have waiting for requests. See min_spare_servers.
    max_servers       => $dev?8: 60, # Default: 50 -  The maximum number of child servers to start. This does not apply to dequeue processes.
    max_requests      => 1200,       # Default: 1000 
    check_for_dead    => 24,         # Default: 30
    check_for_waiting => 8,          # Default: 10 -  Seconds to wait before checking to see if we can kill off some waiting servers.
    log_level         => 2,          # Default: 2  -  3 to see client-ip's, 4 to see process-ids
    host              => '0.0.0.0',  # If not set to [0.0.0.0], Net::Server will listen to [::] and enables IPv6
);


### START THE SERVER
if ( $ARGV[0] ) {
    API::server->new($ARGV[0])->run( %preforkOptions );
} else { 
    print "1st parameter must be the server port. Exit!\n";
    exit 0;
}


1;