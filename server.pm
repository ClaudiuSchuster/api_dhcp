package API::server;

use strict; use warnings; use utf8; use feature ':5.10';


### Load HTTP::Server::Simple::CGI::PreFork which use Net::Server::PreFork (requires IPv6 on host)
use HTTP::Server::Simple::CGI::PreFork;
use base qw(HTTP::Server::Simple::CGI::PreFork);

### Load our json module
use json;
### Load our html-site modules. Note: Modules must have a print() function!
use html::dhcp;
use html::readme;


### Load our CGI module and initialize it
sub cgi_init {
    my $self = shift;
    if (@_) {
        $self->{cgi_init} = shift;
    }
    return $self->{cgi_init} || sub { require modules::CGI; CGI::initialize_globals()};
    
}

### Serve the requests... (Generate JSON, or check if we have a html module loaded for this URI and serve it :)
sub handle_request {
    my %dispatch = (
        '/' => \&API::json::print
    );
    my $self = shift;
    my $cgi  = shift;
    my $path = $cgi->path_info();
    my @loaded_html_modules = map /html\/(\w+)\.pm/, sort keys %INC;
    my ($uri) = grep { $path =~ /^\/$_\/?$/ } @loaded_html_modules;
    
    my $handler;
    if( defined $uri ) {
        {
            no strict 'refs';
            $dispatch{$uri} = \&{"API::html::${uri}::print"};
        }
        $handler = $dispatch{$uri};  # automatical load SITENAME html-page if a html::SITENAME module is loaded
    } else {
        $handler = $dispatch{$path}; # select from pre-initialized %dispatch
    }

    if( ref($handler) eq "CODE") {
        print "HTTP/1.0 200 OK\r\n";
        &$handler($cgi);
    } else {
        print "HTTP/1.0 404 Not found\r\n";
        print $cgi->header, $cgi->start_html('404 Not found'), $cgi->h1("404 Not found");
        for ( @loaded_html_modules ) {
            print "\n<p>Goto:<a style='margin-left:10px;' href='/$_'>".uc($_)."</a></p>";
        }
        print "\n<p>Goto:<a style='margin-left:10px;' href='/'>JSON API</a></p>";
        print $cgi->end_html;
    }
}


1;
