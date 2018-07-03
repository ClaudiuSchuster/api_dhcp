package API::json;

use strict; use warnings; use utf8; use feature ':5.10';

use JSON;

### Load our api-method modules. Note: Modules must have a run() function!
use methods::dhcp;
use methods::eth;
use methods::mine;


### Create and print the JSON Object
sub print { 
    my $cgi = shift;
    
    ### Initialize JSON structure
    my $json_ref = {
        meta => {
            rc => 200,
            msg => undef,
            method => undef,
            json => undef
        },
        data => {}
    };
    
    ### Check if module for requested method is loaded, execute the method and fill the data{}-object
    if( defined $cgi->param('method') ) {
        my ($method) = grep { $cgi->param('method') =~ /^($_|$_\/?\w*)$/ }  map /methods\/(\w+)\.pm/, keys %INC;
        if( defined $method ) {
            {
                no strict 'refs';
                my $method_run_ref = \&{"API::methods::${method}::run"};
                my $method_run_result = $method_run_ref->($cgi,$json_ref);
                $json_ref->{'data'}{$method} = $method_run_result->{data};
            }
            $json_ref->{'data'}{$method} = {} if( $cgi->param('nodata') );
        }
    }
    
    ### Print JSON object
    print $cgi->header('application/json'), JSON->new->pretty->encode($json_ref);
}


1;
