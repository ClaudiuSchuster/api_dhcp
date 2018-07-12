package API::methods::dhcp;

use strict; use warnings; use utf8; use feature ':5.10';

use JSON;
## Load Net::ISC::DHCPd 0.1709
use Net::ISC::DHCPd::Config;
use Net::ISC::DHCPd::Leases;
## Load our dhcp modules...
use methods::dhcp::service;
use methods::dhcp::group;
use methods::dhcp::host;


sub run {
    my $cgi = shift;
    my $json = shift;
    my $isHtml = shift;
    
    ### Initialize dhcp paths...
    my $path_dhcpd_bin    = '/usr/sbin/dhcpd';
    my $path_dhcpd_conf   = '/etc/dhcp/dhcpd.conf';
    my $path_dhcpd_leases = '/var/lib/dhcp/dhcpd.leases';
    
    ### Parsing dhcpd.conf and leases
    my ($config, $leases);
    eval {
        $config = Net::ISC::DHCPd::Config->new( file => $path_dhcpd_conf );
        $config->parse; # parse the config
        for my $include ($config->includes) { $include->parse; } # parsing includes are lazy
        $leases = Net::ISC::DHCPd::Leases->new( file => $path_dhcpd_leases );
        $leases->parse; # parse the leases file
        1; 
    } or do {
        return { 'rc' => 500, 'msg' => "error.parse.dhcp.configNleases: ".$@ };
    };

    ### sub: generate dhcp config and returns it
    my $generate_config = sub {
        my $conf = $config->generate;
        $conf .= "}\n";
        $conf =~ s/\s*(filename\s+"ipxe.efi")/\n          $1/;
        
        return $conf;
    };
    ### sub: write dhcp config to disk
    my $write_dhcpd_conf = sub {
        open (OUT, "> $path_dhcpd_conf") or do {
            return { 'rc' => 500, 'msg' => "error.write_dhcpd_conf: Could not open output file for write '$path_dhcpd_conf'!: ".$@ };
        };
        my @contents = split '\n', $generate_config->();
        foreach my $line (@contents) {
            chomp($line);
            next if ( $line =~ /^\s*$/m );
            print OUT "$line\n";
        }
        close (OUT);
        
        return undef;
    };
    ### sub: Create %dhcpd hash with all infos from DHCPD
    my $create_dhcp_hash = sub {
        my $pid = API::helpers::trim(`pidof $path_dhcpd_bin`) || 0;
        $json->{data}{dhcp}{status} = {
            active => $pid ? \1 : \0,
            lstart => $pid ? API::helpers::trim(`ps -o lstart= -p $pid`) : undef,
            etimes => $pid ? API::helpers::trim(`ps -o etimes= -p $pid`) : undef,
        };
        for my $group ( $config->find_groups({}) ) {
            for ( $group->options ) {
                $json->{data}{dhcp}{'groups'}{$group->{name}}{'options'}{$_->{name}} = $_->{value};
            }
            for my $host ( @{$group->hosts} ) {
                my $mac = $host->_children->[0]->{value};
                my ($lease) = grep { $_->hardware_address =~ /$mac/i } @{$leases->leases};
                $json->{data}{dhcp}{'groups'}{$group->{name}}{'hosts'}{$host->{name}} = {
                    name             => $host->{name},
                    hardware_address => $host->_children->[0]->{value},
                    vivso            => $host->options->[0]->{value},
                };
                $json->{data}{dhcp}{'groups'}{$group->{name}}{'hosts'}{$host->{name}}{'lease'} = {
                   ip_address => $lease->ip_address, client_hostname => $lease->client_hostname,
                   state => $lease->state, starts => $lease->starts, ends => $lease->ends,
                } if( defined $lease );
            }
            $json->{data}{dhcp}{'groups'}{$group->{name}} = {} unless defined($json->{data}{dhcp}{'groups'}{$group->{name}});
        }
        for my $lease ( $leases->leases ) {
            $json->{data}{dhcp}{'leases'}{$lease->ip_address}{'hardware_address'} = $lease->hardware_address;
            $json->{data}{dhcp}{'leases'}{$lease->ip_address}{'client_hostname'}  = $lease->client_hostname;
            $json->{data}{dhcp}{'leases'}{$lease->ip_address}{'starts'}           = $lease->starts;
            $json->{data}{dhcp}{'leases'}{$lease->ip_address}{'state'}            = $lease->state;
            $json->{data}{dhcp}{'leases'}{$lease->ip_address}{'ends'}             = $lease->ends;
            
            my $mac = $lease->hardware_address;
            if( defined $mac ) {
                for my $groupName (sort keys %{$json->{data}{dhcp}{groups}}) {
                    if( defined $json->{data}{dhcp}{groups}{$groupName}{hosts} ) {
                        my ($host) = grep { $json->{data}{dhcp}{groups}{$groupName}{hosts}{$_}->{hardware_address} =~ /$mac/i } keys %{$json->{data}{dhcp}{groups}{$groupName}{hosts}};
                        if( $host ) {
                            $json->{data}{dhcp}{'leases'}{$lease->ip_address}{'host'}             = {
                                name  => $json->{data}{dhcp}{groups}{$groupName}{hosts}{$host}{name},
                                vivso => $json->{data}{dhcp}{groups}{$groupName}{hosts}{$host}{vivso},
                                group => $groupName,
                            };
                            last; 
                        }
                    }
                }
            }
        }
    };
    
    ### Check if subclass and requested function exists before initialize node and execute it.
    my ($reqPackage,$reqSubclass,$reqFunc) = ( $json->{meta}{postdata}{method} =~ /^(\w+)(?:\.(\w+))?(?:\.(\w+))?/ );
    my ($subclass) = grep { $json->{meta}{postdata}{method} =~ /^\w+\.($_)(?:\..*)?$/ }  map /methods\/$reqPackage\/(\w+)\.pm/, keys %INC;
    if( defined $subclass ) {
        my ($subclass_func) = ($json->{meta}{postdata}{method} =~ /^$reqPackage\.$subclass\.(\w+)/);
        my @subs;
        {
            no strict 'refs';
            my $class = 'API::methods::'.$reqPackage.'::'.$subclass.'::';
            @subs = keys %$class;
        }
        if( defined $subclass_func && grep { $_ eq $subclass_func } @subs ) {
            $json->{meta}{method} = $json->{meta}{postdata}{method};
            {
                no strict 'refs';
                my $method_run_ref = \&{"API::methods::${reqPackage}::${subclass}::${subclass_func}"};
                my $method_run_result = $method_run_ref->(
                    $cgi,
                    $config,
                    $json->{meta}{postdata}{params} || undef
                );
                $create_dhcp_hash->($json,$config,$leases);
                $method_run_result = $write_dhcpd_conf->() unless($method_run_result);
                return $method_run_result
                    unless( $isHtml );
            }
        } else {
            return {'rc'=>400,'msg'=>"Requested function '".($reqFunc || '')."' does not exist in package '$reqPackage.$subclass' (class.subclass.function). Abort!"};
        }
    } elsif ( !$reqSubclass || $reqSubclass eq '' || $reqSubclass eq 'get' ) {
        $create_dhcp_hash->($json,$config,$leases);
        return {'rc'=>200, 'method' => defined $reqSubclass && $reqSubclass eq 'get' ? $reqPackage.'.'.$reqSubclass : $reqPackage }
            unless( $isHtml );
    } else {
            return {'rc'=>400,'msg'=>"Requested subclass '".($reqSubclass || '')."' does not exist in class '$reqPackage' (class.subclass.function). Abort!"};
    }
    
    return $generate_config
        if( $isHtml );
}


1;