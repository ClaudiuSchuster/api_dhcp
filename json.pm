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
            postdata => undef
        },
        data => {}
    };
    eval { $json_ref->{meta}{postdata} = decode_json( $cgi->param('POSTDATA') || "{}" ); 1; } or do { 
        $json_ref->{meta}{rc}  = 400;
        $json_ref->{meta}{msg} = 'error.decode_json: '.$@;
    };
    
    ### Check if module for requested method is loaded, execute the method and fill the data{}-object
    if( defined $json_ref->{meta}{postdata}{method} ) {
        my ($method) = grep { $json_ref->{meta}{postdata}{method} =~ /^($_|$_\/?\w*)$/ }  map /methods\/(\w+)\.pm/, keys %INC;
        if( defined $method ) {
            {
                no strict 'refs';
                my $method_run_ref = \&{"API::methods::${method}::run"};
                my $method_run_result = $method_run_ref->($cgi,$json_ref);
                $json_ref->{'data'}{$method} = $method_run_result->{data};
            }
            $json_ref->{'data'}{$method} = {} if( $json_ref->{meta}{postdata}{nodata} );
        }
    }
    
    ### Print JSON object
    print $cgi->header('application/json'), JSON->new->pretty->encode($json_ref);
}


1;
