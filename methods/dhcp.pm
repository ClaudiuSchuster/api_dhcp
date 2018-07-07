package API::methods::dhcp;

use strict; use warnings; use utf8; use feature ':5.10';

use Net::ISC::DHCPd::Config;
use Net::ISC::DHCPd::Leases;
use JSON;


sub run {
    my $cgi = shift;
    my $json = shift;
    ####################  Initialize some stuff...  #########################
    my $dhcpdPath = '/usr/sbin/dhcpd';
    my $filename = '/etc/dhcp/dhcpd.conf';
    my $leasefile = '/var/lib/dhcp/dhcpd.leases';
    $json->{meta}{method} = $json->{meta}{postdata}{method} if( defined $json->{meta}{postdata}{method} && $json->{meta}{postdata}{method} eq 'dhcp');
    my $params = $json->{meta}{postdata}{params} || undef;
    #########################################################################
    
    ###################  Parsing dhcpd.conf and leases  #####################
    my $config = Net::ISC::DHCPd::Config->new( file => $filename );
    $config->parse; # parse the config
    for my $include ($config->includes) { $include->parse; } # parsing includes are lazy
    my $leases = Net::ISC::DHCPd::Leases->new( file => $leasefile );
    $leases->parse; # parse the leases file
    #########################################################################

    #################  dhcpd.conf modify subroutines  #######################
    my $generateDhcpdConf_sub = sub {
        my $config = $config->generate;
        $config .= "}\n";
        $config =~ s/\s*(filename\s+"ipxe.efi")/\n          $1/;
        return $config;
    };
    my $writeDhcpdConf_sub = sub {
        open (OUT, "> $filename") or do {
            $json->{meta}{rc}  = 500;
            $json->{meta}{msg} = "Error: Could not open output file for write '$filename'!: ".$@;
            return 0;
        };
        my @contents = split '\n', $generateDhcpdConf_sub->();
        foreach my $line (@contents) {
            chomp($line);
            next if ( $line =~ /^\s*$/m );
            print OUT "$line\n";
        }
        close (OUT);
    };
    #########################################################################

    ########################  dhcp/restartservice  ##########################
    if( defined $json->{meta}{postdata}{method} && $json->{meta}{postdata}{method} eq "dhcp.restartservice" ) {
        my $content = API::helpers::trim(`service isc-dhcp-server restart 2>&1`);
        $json->{meta}{method} = $json->{meta}{postdata}{method};
        if( defined $content && $content eq "" ) {
            $json->{'meta'}{'msg'} = undef;
        } elsif ( defined $content && $content ne "" ) {
            $json->{'meta'}{'rc'}  = 500;
            $json->{'meta'}{'msg'} = "Error while restart isc-dhcp-server service! - ".$content;
            return 0;
        }
    }
    ########################  dhcp/addhost         ##########################
    elsif( defined $json->{meta}{postdata}{method} && $json->{meta}{postdata}{method} eq "dhcp.addhost" ) {
        $json->{meta}{method} = $json->{meta}{postdata}{method};
        if ( ref($params) eq 'HASH' ) {
            unless( $params->{group} && $params->{name} && $params->{mac} ) {
                $json->{meta}{rc}  = 400;
                $json->{meta}{msg} = "Insufficient arguments submitted: 'group + name + mac' are needed!";
            } else {
                for my $group ( $config->find_groups({}) ) {
                    for my $host ( @{$group->hosts} ) {
                        my $mac = $host->_children->[0]->{value};
                        my $name = $host->{name};
                        if( $params->{name} =~ /$name/i ) {
                            $json->{meta}{rc}  = 400;
                            $json->{meta}{msg} = "Host name '".$params->{name}."' already exist. Abort!";
                        } elsif ( $params->{mac} =~ /$mac/i) {
                            $json->{meta}{rc}  = 400;
                            $json->{meta}{msg} = "Host hardware_address '".$params->{mac}."' already exist. Abort!";
                        }
                        last if( $json->{meta}{rc} >= 400 );
                    }
                    last if( $json->{meta}{rc} >= 400 );
                }
                if ($json->{meta}{rc} == 200) {
                    my @group = $config->find_groups({ name => $params->{group} });
                    if( scalar @group ) {
                        unless (
                            $group[0]->add_host({
                                name => $params->{name},
                                hardwareethernet => [{ value => $params->{mac} }]
                            })
                        ) {
                            $json->{meta}{rc}  = 500;
                            $json->{meta}{msg} = "Failure during addhost name: '".$params->{name}."' mac: '".$params->{mac}."' in group: '".$params->{group}."'!";
                        } else {
                            $writeDhcpdConf_sub->();
                        }
                    } else {
                        $json->{meta}{rc}  = 400;
                        $json->{meta}{msg} = "Target group '".$params->{group}."' not found. Abort!";
                    }
                }
            }
        } else {
            $json->{meta}{rc}  = 400;
            $json->{meta}{msg} = "No 'params' object{} for method-parameter submitted. Abort!";
        }
    }
    ########################  dhcp/removehost      ##########################
    elsif( defined $json->{meta}{postdata}{method} && $json->{meta}{postdata}{method} eq "dhcp.removehost" ) {
        $json->{meta}{method} = $json->{meta}{postdata}{method};
        if ( ref($params) eq 'HASH' ) {
            unless( $params->{name} || $params->{mac} ) {
                $json->{meta}{rc}  = 400;
                $json->{meta}{msg} = "Insufficient arguments submitted: 'name' or 'mac' are needed!";
            } else {
                my $removable = { host => undef, group => undef, found => 0 };
                for my $group ( $config->find_groups({}) ) {
                    for my $host ( @{$group->hosts} ) {
                        my $mac = $host->_children->[0]->{value};
                        my $name = $host->{name};
                        if( (defined $params->{name} && $params->{name} =~ /$name/i) || (defined $params->{mac} && $params->{mac} =~ /$mac/i) ) {
                            $removable = { host => $host, group => $group, found => 1 };
                            last;
                        }
                    }
                    last if( $removable->{found} );
                }
                unless( $removable->{found} ) {
                    $json->{meta}{rc}  = 400;
                    $json->{meta}{msg} = "Host name or mac '".($params->{name} ? $params->{name} : $params->{mac})."' not found for removal. Abort!";
                }
                if ($json->{meta}{rc} == 200) {
                    unless ( $removable->{group}->remove_hosts($removable->{host}) ) {
                        $json->{meta}{rc}  = 500;
                        $json->{meta}{msg} = "Failure during removal of host '".$removable->{name}."' in group '".$removable->{group}."' for removal!";
                    } else {
                        $writeDhcpdConf_sub->();
                    }
                }
            }
        } else {
            $json->{meta}{rc}  = 400;
            $json->{meta}{msg} = "No 'params' object{} for method-parameter submitted. Abort!";
        }
    }
    ########################  dhcp/alterhost        ##########################
    elsif( defined $json->{meta}{postdata}{method} && $json->{meta}{postdata}{method} eq "dhcp.alterhost" ) {
        $json->{meta}{method} = $json->{meta}{postdata}{method};
        if ( ref($params) eq 'HASH' ) {
            unless( ($params->{name} || $params->{mac}) && ($params->{group} || $params->{newname} || $params->{newmac}) ) {
                $json->{meta}{rc}  = 400;
                $json->{meta}{msg} = "Insufficient arguments submitted: ('name' or 'mac') and ('group' or 'newname' or 'newmac') are required!";
            } else {
                my $movable;
                for my $group ( $config->find_groups({}) ) {
                    for my $host ( @{$group->hosts} ) {
                        my $mac = $host->_children->[0]->{value};
                        my $name = $host->{name};
                        if( (defined $params->{name} && $params->{name} =~ /$name/i) || (defined $params->{mac} && $params->{mac} =~ /$mac/i) ) {
                            $movable = { host => $host, group => $group };
                            last;
                        }
                    }
                    last if( $movable );
                }
                unless( $movable ) {
                    $json->{meta}{rc}  = 400;
                    $json->{meta}{msg} = "Host name or mac '".($params->{name} ? $params->{name} : $params->{mac})."' not found for move. Abort!";
                } else {
                    for my $group ( $config->find_groups({}) ) {
                        for my $host ( @{$group->hosts} ) {
                            my $mac = $host->_children->[0]->{value};
                            my $name = $host->{name};
                            if( defined $params->{newname} && $params->{newname} =~ /$name/i ) {
                                $json->{meta}{rc}  = 400;
                                $json->{meta}{msg} = "Host 'newname' '".$params->{newname}."' already exist. Abort!";
                            } elsif ( defined $params->{newmac} && $params->{newmac} =~ /$mac/i) {
                                $json->{meta}{rc}  = 400;
                                $json->{meta}{msg} = "Host 'newmac' '".$params->{newmac}."' already exist. Abort!";
                            }
                            last if( $json->{meta}{rc} >= 400 );
                        }
                        last if( $json->{meta}{rc} >= 400 );
                    }
                    if ($json->{meta}{rc} == 200) {
                        $params->{group} = $movable->{group}->{name} unless( defined $params->{group} );
                        my @newGroup = $config->find_groups({ name => $params->{group} });
                        if( scalar @newGroup ) {
                            if ( $movable->{group}->remove_hosts($movable->{host}) ) {
                                if ( $params->{group} =~ /winbios|.*-dev/ && defined $params->{name} && $params->{name} !~ /pxe.test.*/i) {
                                    unless (
                                        $newGroup[0]->add_host({
                                            name => defined $params->{newname} ? $params->{newname} : $movable->{host}->{name},
                                            hardwareethernet =>  defined $params->{newmac} ? [{ value => $params->{newmac} }] : [{ value => $movable->{host}->_children->[0]->{value} }],
                                            options => [{ name => "vivso", value => $movable->{group}->{name}, quoted => 1 }]
                                        })
                                    ) {
                                        $json->{meta}{rc}  = 500;
                                        $json->{meta}{msg} = "Failure during addhost-'with vivso' of '".$params->{name}."' in group '".$params->{target}."'!";
                                    } else {
                                        $writeDhcpdConf_sub->();
                                    }
                                } else {
                                    unless (
                                        $newGroup[0]->add_host({
                                            name => defined $params->{newname} ? $params->{newname} : $movable->{host}->{name},
                                            hardwareethernet => defined $params->{newmac} ? [{ value => $params->{newmac} }] : [{ value => $movable->{host}->_children->[0]->{value} }]
                                        })
                                    ) {
                                        $json->{meta}{rc}  = 500;
                                        $json->{meta}{msg} = "Failure during addhost of '".$params->{name}."' in group '".$params->{target}."'!";
                                    } else {
                                        $writeDhcpdConf_sub->();
                                    }
                                }
                            } else {
                                $json->{meta}{rc}  = 500;
                                $json->{meta}{msg} = "Failure during removal of '".$movable->{host}->{name}."' in group '".$movable->{group}->{name}."' for removal!";
                            }
                        } else {
                            $json->{meta}{rc}  = 400;
                            $json->{meta}{msg} = "Target group '".$params->{group}."' not found. Abort!";
                        }
                    }
                }
            }
        } else {
            $json->{meta}{rc}  = 400;
            $json->{meta}{msg} = "No 'params' object{} for method-parameter submitted. Abort!";
        }
    }
    ########################  dhcp/addgroup        ##########################
    elsif( defined $json->{meta}{postdata}{method} && $json->{meta}{postdata}{method} eq "dhcp.addgroup" ) {
        $json->{meta}{method} = $json->{meta}{postdata}{method};
        if ( ref($params) eq 'HASH' ) {
            unless( $params->{group} && $params->{options} ) {
                $json->{meta}{rc}  = 400;
                $json->{meta}{msg} = "Insufficient arguments submitted: 'name + options' are needed! options = [] or ".'[{"name":"op","value":"a","quoted":1},{..},..]';
            } else {
                if( ref($params->{options}) eq 'ARRAY' && ref(${$params->{options}}[0]) eq 'HASH' && !${$params->{options}}[0]->{name} && !${$params->{options}}[0]->{value} && !${$params->{options}}[0]->{quoted}
                  || ref($params->{options}) eq 'ARRAY' && ${$params->{options}}[0] && ref(${$params->{options}}[0]) ne 'HASH' 
                  || ref($params->{options}) ne 'ARRAY' ) {
                    $json->{meta}{rc}  = 400;
                    $json->{meta}{msg} = "Options Argument must be an empty list or a list of options-objects. Abort! options = ".'[{"name":"op","value":"a","quoted":1},{..},..]';
                } else {
                    my @group = $config->find_groups({ name => $params->{group} });
                    if( scalar @group ) {
                        $json->{meta}{rc}  = 400;
                        $json->{meta}{msg} = "Group name '".$params->{group}."' already exist. Abort!";
                    } else {
                        unless (
                            $config->add_group({
                                name => $params->{group},
                                options => $params->{options}   # options => [{ name => "root-path", value => "value", quoted => 1 }]
                            })
                        ) {
                            $json->{meta}{rc}  = 500;
                            $json->{meta}{msg} = "Failure during add_group with name: '".$params->{group}." and options: '".$params->{options}."'!";
                        } else {
                            $writeDhcpdConf_sub->();
                        }
                    }
                }
            }
        } else {
            $json->{meta}{rc}  = 400;
            $json->{meta}{msg} = "No 'params' object{} for method-parameter submitted. Abort!";
        }
    }
    ########################  dhcp/removegroup     ##########################
    elsif( defined $json->{meta}{postdata}{method} && $json->{meta}{postdata}{method} eq "dhcp.removegroup" ) {
        $json->{meta}{method} = $json->{meta}{postdata}{method};
        if ( ref($params) eq 'HASH' ) {
            unless( $params->{group} ) {
                $json->{meta}{rc}  = 400;
                $json->{meta}{msg} = "Insufficient arguments submitted: 'group' are needed!";
            } else {
                my @group = $config->find_groups({ name => $params->{group} });
                if( !scalar @group ) {
                    $json->{meta}{rc}  = 400;
                    $json->{meta}{msg} = "Group name '".$params->{group}."' not found for removal. Abort!";
                } elsif ( scalar @{$group[0]->hosts} > 0) {
                    $json->{meta}{rc}  = 400;
                    $json->{meta}{msg} = "Group '".$group[0]->{name}."' has '".(scalar @{$group[0]->hosts})."' hosts inside. Move or delete hosts before group removal. Abort!";
                } else {
                    unless ( $config->remove_groups($group[0]) ) {
                        $json->{meta}{rc}  = 500;
                        $json->{meta}{msg} = "Failure during removal of group '".$group[0]->{name}."'!";
                    } else {
                        $writeDhcpdConf_sub->();
                    }
                }
            }
        } else {
            $json->{meta}{rc}  = 400;
            $json->{meta}{msg} = "No 'params' object{} for method-parameter submitted. Abort!";
        }
    }
    ########################  dhcp/altergroup      ##########################
    elsif( defined $json->{meta}{postdata}{method} && $json->{meta}{postdata}{method} eq "dhcp.altergroup" ) {
        $json->{meta}{method} = $json->{meta}{postdata}{method};
        if ( ref($params) eq 'HASH' ) {
            unless( $params->{group} && ($params->{options} || $params->{name}) ) {
                $json->{meta}{rc}  = 400;
                $json->{meta}{msg} = "Insufficient arguments submitted: 'group' and ('name' or/and 'options') are required! options = ".'[{"name":"op","value":"a","quoted":1},{..},..]';
            }
            if ($json->{meta}{rc} == 200) {
                if( defined $params->{options} && ref($params->{options}) eq 'ARRAY' && ref(${$params->{options}}[0]) eq 'HASH' && (!${$params->{options}}[0]->{name} || !${$params->{options}}[0]->{value} || !${$params->{options}}[0]->{quoted})
                  || defined $params->{options} && ref($params->{options}) eq 'ARRAY' && ${$params->{options}}[0] && ref(${$params->{options}}[0]) ne 'HASH' ) {
                    $json->{meta}{rc}  = 400;
                    $json->{meta}{msg} = "Options Argument must be an empty list or a list of options-objects. Abort! options = ".'[{"name":"op","value":"a","quoted":1},{..},..]';
                }
                if ($json->{meta}{rc} == 200) {
                    my @group = $config->find_groups({ name => $params->{group} });
                    unless( scalar @group ) {
                        $json->{meta}{rc}  = 400;
                        $json->{meta}{msg} = "Group name '".$params->{group}."' not found for altering. Abort!";
                    } else {
                        if( defined $params->{name} ) {
                            my @newgroup = $config->find_groups({ name => $params->{name} });
                            if( scalar @newgroup ) {
                                $json->{meta}{rc}  = 400;
                                $json->{meta}{msg} = "Target group name '".$params->{name}."' already exists. Abort!";
                            } else {
                                unless (
                                    $config->add_group({
                                        name => $params->{name},
                                        options => defined $params->{options} ? $params->{options} : [$group[0]->options]
                                    })
                                ) {
                                    $json->{meta}{rc}  = 500;
                                    $json->{meta}{msg} = "Failure during add_group with name: '".$params->{group}." and options: '".$group[0]->{options}."'!";
                                } else {
                                    unless ( scalar @{$group[0]->hosts} ) { # group has no hosts
                                        unless ( $config->remove_groups($group[0]) ) {
                                            $json->{meta}{rc}  = 500;
                                            $json->{meta}{msg} = "Failure during removal of group '".$group[0]->{name}."'!";
                                        } else {
                                            $writeDhcpdConf_sub->();
                                        }
                                    } else  { # group has hosts
                                        @newgroup = $config->find_groups({ name => $params->{name} });
                                        unless ( scalar @newgroup ) {
                                            $json->{meta}{rc}  = 500;
                                            $json->{meta}{msg} = "Failure during requesting new created group. Abort!";
                                        } else {
                                            for my $host ( @{$group[0]->hosts} ) {
                                                unless ( $group[0]->remove_hosts($host) ) {
                                                    $json->{meta}{rc}  = 500;
                                                    $json->{meta}{msg} = "Failure during removal of host '".$host->{name}."' in group '".$group[0]->{group}."'!";
                                                    last;
                                                }
                                                unless ( $newgroup[0]->add_host($host) ) {
                                                    $json->{meta}{rc}  = 500;
                                                    $json->{meta}{msg} = "Failure during add_host name: '".$host->{name}."' in group: '".$newgroup[0]->{name}."'!";
                                                    last;
                                                }
                                            }
                                            if($json->{meta}{rc} == 200) {
                                                unless ( $config->remove_groups($group[0]) ) {
                                                    $json->{meta}{rc}  = 500;
                                                    $json->{meta}{msg} = "Failure during removal of group '".$group[0]->{name}."'!";
                                                } else {
                                                    $writeDhcpdConf_sub->();
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        } else {   # change only group options (delete 1st all, then add all again)  [{ name => "root-path", value => "value", quoted => 1 }];
                            my $optionscount = scalar @{$group[0]->options};
                            my $processedOptions = 0;
                            for ( @{$group[0]->options} ) {
                                $processedOptions++ if $group[0]->remove_options($_);
                            }
                            unless ( $optionscount == $processedOptions ) {
                                $json->{meta}{rc}  = 500;
                                $json->{meta}{msg} = "Failure during removal of options from group: '".$group[0]->{name}."' !";
                            } else {
                                $optionscount = scalar @{$params->{options}};
                                $processedOptions = 0;
                                for ( @{$params->{options}} ) {
                                    $processedOptions++ if $group[0]->add_option($_);
                                }
                                unless ( $optionscount == $processedOptions ) {
                                    $json->{meta}{rc}  = 500;
                                    $json->{meta}{msg} = "Failure during adding of options to group: '".$group[0]->{name}."' !";
                                } else {
                                    $writeDhcpdConf_sub->();
                                }
                            }
                        }
                    }
                }
            }
        } else {
            $json->{meta}{rc}  = 400;
            $json->{meta}{msg} = "No 'params' object{} for method-parameter submitted. Abort!";
        }
    }
    #########################################################################

    ##############  Create %dhcpd hash with all infos from DHCPD  ###########
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
    #########################################################################
    
    return {
       data => \%dhcpd,
       generateDhcpdConf_sub => $generateDhcpdConf_sub,
    };
}


1;