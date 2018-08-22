package API::methods::dhcp::host;

use strict; use warnings; use utf8; use feature ':5.10';


sub add {
    my $cgi=shift; my $config=shift; my $params=shift;
    
    return { 'rc' => 400, 'msg' => "No 'params' object{} for method-parameter submitted. Abort!" }
        unless( ref($params) eq 'HASH' );
    return { 'rc' => 400, 'msg' => "Insufficient arguments submitted: 'group + name + mac' are needed!" }
        unless( $params->{group} && $params->{name} && $params->{mac} );
    
    for my $group ( $config->find_groups({}) ) {
        for my $host ( @{$group->hosts} ) {
            my $mac = $host->_children->[0]->{value};
            my $name = $host->{name};
            return { 'rc' => 400, 'msg' => "Host name '".$params->{name}."' already exist. Abort!" }
                if( $params->{name} =~ /^$name$/i );
            return { 'rc' => 400, 'msg' => "Host hardware_address '".$params->{mac}."' already exist. Abort!" }
                if ( $params->{mac} =~ /^$mac$/i);
        }
    }
    my @group = $config->find_groups({ name => $params->{group} });
    return { 'rc' => 400, 'msg' => "Target group '".$params->{group}."' not found. Abort!" }
        unless( scalar @group );
    return { 'rc' => 500, 'msg' => "Failure during addhost name: '".$params->{name}."' mac: '".$params->{mac}."' in group: '".$params->{group}."'!" }
        unless( $group[0]->add_host({
			name => $params->{name},
			hardwareethernet => [{ value => $params->{mac} }],
			keyvalues => [{ name => 'ddns-hostname', value => $params->{name}, quoted => 1}]
		}) );

    return { 'rc' => 200 };
}

sub remove {
    my $cgi=shift; my $config=shift; my $params=shift;
    
    return { 'rc' => 400, 'msg' => "No 'params' object{} for method-parameter submitted. Abort!" }
        unless( ref($params) eq 'HASH' );
    return { 'rc' => 400, 'msg' => "Insufficient arguments submitted: 'name' or 'mac' are needed!" }
        unless( $params->{name} || $params->{mac} );
    
    my $removable = { host => undef, group => undef, found => 0 };
    for my $group ( $config->find_groups({}) ) {
        for my $host ( @{$group->hosts} ) {
            my $mac = $host->_children->[0]->{value};
            my $name = $host->{name};
            if( (defined $params->{name} && $params->{name} =~ /^$name$/i) || (defined $params->{mac} && $params->{mac} =~ /^$mac$/i) ) {
                $removable = { host => $host, group => $group, found => 1 };
                last;
            }
        }
        last if( $removable->{found} );
    }
    return { 'rc' => 400, 'msg' => "Host name or mac '".($params->{name} ? $params->{name} : $params->{mac})."' not found for removal. Abort!" }
        unless( $removable->{found} );
    return { 'rc' => 500, 'msg' => "Failure during removal of host '".$removable->{name}."' in group '".$removable->{group}."' for removal!" }
        unless( $removable->{group}->remove_hosts($removable->{host}) );

    return { 'rc' => 200 };
}

sub alter {
    my $cgi=shift; my $config=shift; my $params=shift;
    
    return { 'rc' => 400, 'msg' => "No 'params' object{} for method-parameter submitted. Abort!" }
        unless( ref($params) eq 'HASH' );
    return { 'rc' => 400, 'msg' => "Insufficient arguments submitted: ('name' or 'mac') and ('group' or 'newname' or 'newmac') are required!" }
        unless( ($params->{name} || $params->{mac}) && ($params->{group} || $params->{newname} || $params->{newmac}) );

    my $movable;
    for my $group ( $config->find_groups({}) ) {
        for my $host ( @{$group->hosts} ) {
            my $mac = $host->_children->[0]->{value};
            my $name = $host->{name};
            if( (defined $params->{name} && $params->{name} =~ /^$name$/i) || (defined $params->{mac} && $params->{mac} =~ /^$mac$/i) ) {
                $movable = { host => $host, group => $group };
                last;
            }
        }
        last if( $movable );
    }
    return { 'rc' => 400, 'msg' => "Host name or mac '".($params->{name} ? $params->{name} : $params->{mac})."' not found for move. Abort!" }
        unless( $movable );
    for my $group ( $config->find_groups({}) ) {
        for my $host ( @{$group->hosts} ) {
            my $mac = $host->_children->[0]->{value};
            my $name = $host->{name};
            return { 'rc' => 400, 'msg' => "Host 'newname' '".$params->{newname}."' already exist. Abort!" }
                if( defined $params->{newname} && $params->{newname} =~ /^$name$/i );
            return { 'rc' => 400, 'msg' => "Host 'newmac' '".$params->{newmac}."' already exist. Abort!" }
                if( defined $params->{newmac} && $params->{newmac} =~ /^$mac$/i );
        }
    }
    $params->{group} = $movable->{group}->{name} unless( defined $params->{group} );
    my @newGroup = $config->find_groups({ name => $params->{group} });
    return { 'rc' => 400, 'msg' => "Target group '".$params->{group}."' not found. Abort!" }
        unless( scalar @newGroup );
    return { 'rc' => 500, 'msg' => "Failure during removal of '".$movable->{host}->{name}."' in group '".$movable->{group}->{name}."' for removal!" }
        unless( $movable->{group}->remove_hosts($movable->{host}) );
    if ( $params->{group} =~ /winbios|.*-dev/ && defined $params->{name} && $params->{name} !~ /pxe.test.*/i) {
        return { 'rc' => 500, 'msg' => "Failure during addhost-'with vivso' of '".$params->{name}."' in group '".$params->{target}."'!" }
            unless(
                $newGroup[0]->add_host({
                    name => defined $params->{newname} ? $params->{newname} : $movable->{host}->{name},
                    hardwareethernet =>  defined $params->{newmac} ? [{ value => $params->{newmac} }] : [{ value => $movable->{host}->_children->[0]->{value} }],
                    options => [{ name => "vivso", value => $movable->{group}->{name}, quoted => 1 }],
					keyvalues => [{ name => 'ddns-hostname', value => defined $params->{newname} ? $params->{newname} : $movable->{host}->{name}, quoted => 1}]
                })
            );
    } else {
        return { 'rc' => 500, 'msg' => "Failure during addhost of '".$params->{name}."' in group '".$params->{target}."'!" }
            unless(
                $newGroup[0]->add_host({
                    name => defined $params->{newname} ? $params->{newname} : $movable->{host}->{name},
                    hardwareethernet => defined $params->{newmac} ? [{ value => $params->{newmac} }] : [{ value => $movable->{host}->_children->[0]->{value} }],
					keyvalues => [{ name => 'ddns-hostname', value => defined $params->{newname} ? $params->{newname} : $movable->{host}->{name}, quoted => 1}]
                })
            );
    }

    return { 'rc' => 200 };
}


1;