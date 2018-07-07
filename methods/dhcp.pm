package API::methods::dhcp;

use strict; use warnings; use utf8; use feature ':5.10';

use Net::ISC::DHCPd::Config;
use Net::ISC::DHCPd::Leases;
use JSON;


sub run {
    my $q = shift;  # CGI-Object
    my $json = shift;
    ####################  Initialize some stuff...  #########################
    my $dhcpdPath = '/usr/sbin/dhcpd';
    my $filename = '/etc/dhcp/dhcpd.conf';
    my $leasefile = '/var/lib/dhcp/dhcpd.leases';
    $json->{meta}{method} = 'dhcp' if($json->{meta}{postdata}{method} eq 'dhcp');
    my $postdata = $json->{meta}{postdata}{data} || undef;
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
    if( $json->{meta}{postdata}{method} eq "dhcp.restartservice" ) {
        my $content = API::helpers::trim(`service isc-dhcp-server restart`);
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
    elsif( $json->{meta}{postdata}{method} eq "dhcp.addhost" ) {
        $json->{meta}{method} = $json->{meta}{postdata}{method};
        if ( ref($postdata) eq 'HASH' ) {
            unless( $postdata->{group} && $postdata->{name} && $postdata->{mac} ) {
                $json->{meta}{rc}  = 400;
                $json->{meta}{msg} = "Insufficient arguments submitted: 'group + name + mac' are needed!";
            } else {
                for my $group ( $config->find_groups({}) ) {
                    for my $host ( @{$group->hosts} ) {
                        my $mac = $host->_children->[0]->{value};
                        my $name = $host->{name};
                        if( $postdata->{name} =~ /$name/i ) {
                            $json->{meta}{rc}  = 400;
                            $json->{meta}{msg} = "Host name '".$postdata->{name}."' already exist. Abort!";
                        } elsif ( $postdata->{mac} =~ /$mac/i) {
                            $json->{meta}{rc}  = 400;
                            $json->{meta}{msg} = "Host hardware_address '".$postdata->{mac}."' already exist. Abort!";
                        }
                        last if( $json->{meta}{rc} >= 400 );
                    }
                    last if( $json->{meta}{rc} >= 400 );
                }
                if ($json->{meta}{rc} == 200) {
                    my @group = $config->find_groups({ name => $postdata->{group} });
                    if( scalar @group ) {
                        unless (
                            $group[0]->add_host({
                                name => $postdata->{name},
                                hardwareethernet => [{ value => $postdata->{mac} }]
                            })
                        ) {
                            $json->{meta}{rc}  = 500;
                            $json->{meta}{msg} = "Failure during addhost name: '".$postdata->{name}."' mac: '".$postdata->{mac}."' in group: '".$postdata->{group}."'!";
                        } else {
                            $writeDhcpdConf_sub->();
                        }
                    } else {
                        $json->{meta}{rc}  = 400;
                        $json->{meta}{msg} = "Target group '".$postdata->{group}."' not found. Abort!";
                    }
                }
            }
        } else {
            $json->{meta}{rc}  = 400;
            $json->{meta}{msg} = "No data object for method submitted. Abort!";
        }
    }
    ########################  dhcp/removehost      ##########################
    elsif( $json->{meta}{postdata}{method} eq "dhcp.removehost" ) {
        $json->{meta}{method} = $json->{meta}{postdata}{method};
        if ( ref($postdata) eq 'HASH' ) {
            unless( $postdata->{name} || $postdata->{mac} ) {
                $json->{meta}{rc}  = 400;
                $json->{meta}{msg} = "Insufficient arguments submitted: 'name' or 'mac' are needed!";
            } else {
                my $removable = { host => undef, group => undef, found => 0 };
                for my $group ( $config->find_groups({}) ) {
                    for my $host ( @{$group->hosts} ) {
                        my $mac = $host->_children->[0]->{value};
                        my $name = $host->{name};
                        if( (defined $postdata->{name} && $postdata->{name} =~ /$name/i) || (defined $postdata->{mac} && $postdata->{mac} =~ /$mac/i) ) {
                            $removable = { host => $host, group => $group, found => 1 };
                            last;
                        }
                    }
                    last if( $removable->{found} );
                }
                unless( $removable->{found} ) {
                    $json->{meta}{rc}  = 400;
                    $json->{meta}{msg} = "Host name or mac '".($postdata->{name} ? $postdata->{name} : $postdata->{mac})."' not found for removal. Abort!";
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
            $json->{meta}{msg} = "No data object for method submitted. Abort!";
        }
    }
    ########################  dhcp/alterhost        ##########################
    elsif( $json->{meta}{postdata}{method} eq "dhcp.alterhost" ) {
        $json->{meta}{method} = $json->{meta}{postdata}{method};
        if ( ref($postdata) eq 'HASH' ) {
            unless( ($postdata->{name} || $postdata->{mac}) && ($postdata->{group} || $postdata->{newname} || $postdata->{newmac}) ) {
                $json->{meta}{rc}  = 400;
                $json->{meta}{msg} = "Insufficient arguments submitted: ('name' or 'mac') and ('group' or 'newname' or 'newmac') are required!";
            } else {
                my $movable;
                for my $group ( $config->find_groups({}) ) {
                    for my $host ( @{$group->hosts} ) {
                        my $mac = $host->_children->[0]->{value};
                        my $name = $host->{name};
                        if( (defined $postdata->{name} && $postdata->{name} =~ /$name/i) || (defined $postdata->{mac} && $postdata->{mac} =~ /$mac/i) ) {
                            $movable = { host => $host, group => $group };
                            last;
                        }
                    }
                    last if( $movable );
                }
                unless( $movable ) {
                    $json->{meta}{rc}  = 400;
                    $json->{meta}{msg} = "Host name or mac '".($postdata->{name} ? $postdata->{name} : $postdata->{mac})."' not found for move. Abort!";
                } else {
                    for my $group ( $config->find_groups({}) ) {
                        for my $host ( @{$group->hosts} ) {
                            my $mac = $host->_children->[0]->{value};
                            my $name = $host->{name};
                            if( defined $postdata->{newname} && $postdata->{newname} =~ /$name/i ) {
                                $json->{meta}{rc}  = 400;
                                $json->{meta}{msg} = "Host 'newname' '".$postdata->{newname}."' already exist. Abort!";
                            } elsif ( defined $postdata->{newmac} && $postdata->{newmac} =~ /$mac/i) {
                                $json->{meta}{rc}  = 400;
                                $json->{meta}{msg} = "Host 'newmac' '".$postdata->{newmac}."' already exist. Abort!";
                            }
                            last if( $json->{meta}{rc} >= 400 );
                        }
                        last if( $json->{meta}{rc} >= 400 );
                    }
                    if ($json->{meta}{rc} == 200) {
                        $postdata->{group} = $movable->{group}->{name} unless( defined $postdata->{group} );
                        my @newGroup = $config->find_groups({ name => $postdata->{group} });
                        if( scalar @newGroup ) {
                            if ( $movable->{group}->remove_hosts($movable->{host}) ) {
                                if ( $postdata->{group} =~ /winbios|.*-dev/ && defined $postdata->{name} && $postdata->{name} !~ /pxe.test.*/i) {
                                    unless (
                                        $newGroup[0]->add_host({
                                            name => defined $postdata->{newname} ? $postdata->{newname} : $movable->{host}->{name},
                                            hardwareethernet =>  defined $postdata->{newmac} ? [{ value => $postdata->{newmac} }] : [{ value => $movable->{host}->_children->[0]->{value} }],
                                            options => [{ name => "vivso", value => $movable->{group}->{name}, quoted => 1 }]
                                        })
                                    ) {
                                        $json->{meta}{rc}  = 500;
                                        $json->{meta}{msg} = "Failure during addhost-'with vivso' of '".$postdata->{name}."' in group '".$postdata->{target}."'!";
                                    } else {
                                        $writeDhcpdConf_sub->();
                                    }
                                } else {
                                    unless (
                                        $newGroup[0]->add_host({
                                            name => defined $postdata->{newname} ? $postdata->{newname} : $movable->{host}->{name},
                                            hardwareethernet => defined $postdata->{newmac} ? [{ value => $postdata->{newmac} }] : [{ value => $movable->{host}->_children->[0]->{value} }]
                                        })
                                    ) {
                                        $json->{meta}{rc}  = 500;
                                        $json->{meta}{msg} = "Failure during addhost of '".$postdata->{name}."' in group '".$postdata->{target}."'!";
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
                            $json->{meta}{msg} = "Target group '".$postdata->{group}."' not found. Abort!";
                        }
                    }
                }
            }
        } else {
            $json->{meta}{rc}  = 400;
            $json->{meta}{msg} = "No data object for method submitted. Abort!";
        }
    }
    ########################  dhcp/addgroup        ##########################
    elsif( $json->{meta}{postdata}{method} eq "dhcp.addgroup" ) {
        $json->{meta}{method} = $json->{meta}{postdata}{method};
        if ( ref($postdata) eq 'HASH' ) {
            unless( $postdata->{group} && $postdata->{options} ) {
                $json->{meta}{rc}  = 400;
                $json->{meta}{msg} = "Insufficient arguments submitted: 'name + options' are needed! options = [] or ".'[{"name":"op","value":"a","quoted":1},{..},..]';
            } else {
                if( ref($postdata->{options}) eq 'ARRAY' && ref(${$postdata->{options}}[0]) eq 'HASH' && !${$postdata->{options}}[0]->{name} && !${$postdata->{options}}[0]->{value} && !${$postdata->{options}}[0]->{quoted}
                  || ref($postdata->{options}) eq 'ARRAY' && ${$postdata->{options}}[0] && ref(${$postdata->{options}}[0]) ne 'HASH' 
                  || ref($postdata->{options}) ne 'ARRAY' ) {
                    $json->{meta}{rc}  = 400;
                    $json->{meta}{msg} = "Options Argument must be an empty list or a list of options-objects. Abort! options = ".'[{"name":"op","value":"a","quoted":1},{..},..]';
                } else {
                    my @group = $config->find_groups({ name => $postdata->{group} });
                    if( scalar @group ) {
                        $json->{meta}{rc}  = 400;
                        $json->{meta}{msg} = "Group name '".$postdata->{group}."' already exist. Abort!";
                    } else {
                        unless (
                            $config->add_group({
                                name => $postdata->{group},
                                options => $postdata->{options}   # options => [{ name => "root-path", value => "value", quoted => 1 }]
                            })
                        ) {
                            $json->{meta}{rc}  = 500;
                            $json->{meta}{msg} = "Failure during add_group with name: '".$postdata->{group}." and options: '".$postdata->{options}."'!";
                        } else {
                            $writeDhcpdConf_sub->();
                        }
                    }
                }
            }
        } else {
            $json->{meta}{rc}  = 400;
            $json->{meta}{msg} = "No data object for method submitted. Abort!";
        }
    }
    ########################  dhcp/removegroup     ##########################
    elsif( $json->{meta}{postdata}{method} eq "dhcp.removegroup" ) {
        $json->{meta}{method} = $json->{meta}{postdata}{method};
        if ( ref($postdata) eq 'HASH' ) {
            unless( $postdata->{group} ) {
                $json->{meta}{rc}  = 400;
                $json->{meta}{msg} = "Insufficient arguments submitted: 'group' are needed!";
            } else {
                my @group = $config->find_groups({ name => $postdata->{group} });
                if( !scalar @group ) {
                    $json->{meta}{rc}  = 400;
                    $json->{meta}{msg} = "Group name '".$postdata->{group}."' not found for removal. Abort!";
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
            $json->{meta}{msg} = "No data object for method submitted. Abort!";
        }
    }
    ########################  dhcp/altergroup      ##########################
    elsif( $json->{meta}{postdata}{method} eq "dhcp.altergroup" ) {
        $json->{meta}{method} = $json->{meta}{postdata}{method};
        if ( ref($postdata) eq 'HASH' ) {
            unless( $postdata->{group} && ($postdata->{options} || $postdata->{name}) ) {
                $json->{meta}{rc}  = 400;
                $json->{meta}{msg} = "Insufficient arguments submitted: 'group' and ('name' or/and 'options') are required! options = ".'[{"name":"op","value":"a","quoted":1},{..},..]';
            }
            if ($json->{meta}{rc} == 200) {
                if( defined $postdata->{options} && ref($postdata->{options}) eq 'ARRAY' && ref(${$postdata->{options}}[0]) eq 'HASH' && (!${$postdata->{options}}[0]->{name} || !${$postdata->{options}}[0]->{value} || !${$postdata->{options}}[0]->{quoted})
                  || defined $postdata->{options} && ref($postdata->{options}) eq 'ARRAY' && ${$postdata->{options}}[0] && ref(${$postdata->{options}}[0]) ne 'HASH' ) {
                    $json->{meta}{rc}  = 400;
                    $json->{meta}{msg} = "Options Argument must be an empty list or a list of options-objects. Abort! options = ".'[{"name":"op","value":"a","quoted":1},{..},..]';
                }
                if ($json->{meta}{rc} == 200) {
                    my @group = $config->find_groups({ name => $postdata->{group} });
                    unless( scalar @group ) {
                        $json->{meta}{rc}  = 400;
                        $json->{meta}{msg} = "Group name '".$postdata->{group}."' not found for altering. Abort!";
                    } else {
                        if( defined $postdata->{name} ) {
                            my @newgroup = $config->find_groups({ name => $postdata->{name} });
                            if( scalar @newgroup ) {
                                $json->{meta}{rc}  = 400;
                                $json->{meta}{msg} = "Target group name '".$postdata->{name}."' already exists. Abort!";
                            } else {
                                unless (
                                    $config->add_group({
                                        name => $postdata->{name},
                                        options => defined $postdata->{options} ? $postdata->{options} : [$group[0]->options]
                                    })
                                ) {
                                    $json->{meta}{rc}  = 500;
                                    $json->{meta}{msg} = "Failure during add_group with name: '".$postdata->{group}." and options: '".$group[0]->{options}."'!";
                                } else {
                                    unless ( scalar @{$group[0]->hosts} ) { # group has no hosts
                                        unless ( $config->remove_groups($group[0]) ) {
                                            $json->{meta}{rc}  = 500;
                                            $json->{meta}{msg} = "Failure during removal of group '".$group[0]->{name}."'!";
                                        } else {
                                            $writeDhcpdConf_sub->();
                                        }
                                    } else  { # group has hosts
                                        @newgroup = $config->find_groups({ name => $postdata->{name} });
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
                                $optionscount = scalar @{$postdata->{options}};
                                $processedOptions = 0;
                                for ( @{$postdata->{options}} ) {
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
            $json->{meta}{msg} = "No data object for method submitted. Abort!";
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