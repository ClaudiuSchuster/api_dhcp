package API::methods::dhcp;

use strict; use warnings; use utf8; use feature ':5.10';

## Load Net::ISC::DHCPd 0.1709
use Net::ISC::DHCPd::Config;
use Net::ISC::DHCPd::Leases;
## Load some more modules
use JSON;
## Load our dhcp modules...
use methods::dhcp::service;
use methods::dhcp::group;
use methods::dhcp::host;


### Initialize dhcp paths...
our $dhcpdPath = '/usr/sbin/dhcpd';
our $filename = '/etc/dhcp/dhcpd.conf';
our $leasefile = '/var/lib/dhcp/dhcpd.leases';


sub create_dhcp_hash { ### Create %dhcpd hash with all infos from DHCPD
    my $json = shift;
    my $config = shift;
    my $leases = shift;
    
    my %dhcpd;
    my $pid = API::helpers::trim(`pidof $dhcpdPath`) || 0;
    $dhcpd{status} = {
        active => $pid ? \1 : \0,
        lstart => $pid ? API::helpers::trim(`ps -o lstart= -p $pid`) : undef,
        etimes => $pid ? API::helpers::trim(`ps -o etimes= -p $pid`) : undef,
    };
    for my $group ( $config->find_groups({}) ) {
        for ( $group->options ) {
            $dhcpd{'groups'}{$group->{name}}{'options'}{$_->{name}} = $_->{value};
        }
        for my $host ( @{$group->hosts} ) {
            my $mac = $host->_children->[0]->{value};
            my ($lease) = grep { $_->hardware_address =~ /$mac/i } @{$leases->leases};
            $dhcpd{'groups'}{$group->{name}}{'hosts'}{$host->{name}} = {
                name             => $host->{name},
                hardware_address => $host->_children->[0]->{value},
                vivso            => $host->options->[0]->{value},
            };
            $dhcpd{'groups'}{$group->{name}}{'hosts'}{$host->{name}}{'lease'} = {
               ip_address => $lease->ip_address, client_hostname => $lease->client_hostname,
               state => $lease->state, starts => $lease->starts, ends => $lease->ends,
            } if( defined $lease );
        }
        $dhcpd{'groups'}{$group->{name}} = {} unless defined($dhcpd{'groups'}{$group->{name}});
    }
    for my $lease ( $leases->leases ) {
        $dhcpd{'leases'}{$lease->ip_address}{'hardware_address'} = $lease->hardware_address;
        $dhcpd{'leases'}{$lease->ip_address}{'client_hostname'}  = $lease->client_hostname;
        $dhcpd{'leases'}{$lease->ip_address}{'starts'}           = $lease->starts;
        $dhcpd{'leases'}{$lease->ip_address}{'state'}            = $lease->state;
        $dhcpd{'leases'}{$lease->ip_address}{'ends'}             = $lease->ends;
        
        my $mac = $lease->hardware_address;
        if( defined $mac ) {
            for my $groupName (sort keys %{$dhcpd{groups}}) {
                if( defined $dhcpd{groups}{$groupName}{hosts} ) {
                    my ($host) = grep { $dhcpd{groups}{$groupName}{hosts}{$_}->{hardware_address} =~ /$mac/i } keys %{$dhcpd{groups}{$groupName}{hosts}};
                    if( $host ) {
                        $dhcpd{'leases'}{$lease->ip_address}{'host'}             = {
                            name  => $dhcpd{groups}{$groupName}{hosts}{$host}{name},
                            vivso => $dhcpd{groups}{$groupName}{hosts}{$host}{vivso},
                            group => $groupName,
                        };
                        last; 
                    }
                }
            }
        }
    }
    
    $json->{data}{dhcp} = \%dhcpd;
}

sub run {
    my $cgi = shift;
    my $json = shift;
    my $isHtml = shift;
    
    ### Parsing dhcpd.conf and leases
    my ($config, $leases);
    eval {
        $config = Net::ISC::DHCPd::Config->new( file => $filename );
        $config->parse; # parse the config
        for my $include ($config->includes) { $include->parse; } # parsing includes are lazy
        $leases = Net::ISC::DHCPd::Leases->new( file => $leasefile );
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
        open (OUT, "> $filename") or do {
            return { 'rc' => 500, 'msg' => "error.write_dhcpd_conf: Could not open output file for write '$filename'!: ".$@ };
        };
        my @contents = split '\n', $generate_config->();
        foreach my $line (@contents) {
            chomp($line);
            next if ( $line =~ /^\s*$/m );
            print OUT "$line\n";
        }
        close (OUT);
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
                create_dhcp_hash($json,$config,$leases);
                $write_dhcpd_conf->() unless($method_run_result);
                return $method_run_result
                    unless( $isHtml );
            }
        } else {
            return {'rc'=>400,'msg'=>"Requested function '".($reqFunc || '')."' does not exist in package '$reqPackage.$subclass' (class.subclass.function). Abort!"};
        }
    } elsif ( !$reqSubclass || $reqSubclass eq '' || $reqSubclass eq 'get' ) {
        create_dhcp_hash($json,$config,$leases);
        return { 'method' => defined $reqSubclass && $reqSubclass eq 'get' ? $reqPackage.'.'.$reqSubclass : $reqPackage }
            unless( $isHtml );
    } else {
            return {'rc'=>400,'msg'=>"Requested subclass '".($reqSubclass || '')."' does not exist in class '$reqPackage' (class.subclass.function). Abort!"};
    }
    
    return $generate_config
        if( $isHtml );
}


1;