package API::methods::dhcp::group;

use strict; use warnings; use utf8; use feature ':5.10';


sub add {
    my $cgi=shift; my $config=shift; my $params=shift;
    
    return { 'rc' => 400, 'msg' => "No 'params' object{} for method-parameter submitted. Abort!" }
        unless( ref($params) eq 'HASH' );
    return { 'rc' => 400, 'msg' => "Insufficient arguments submitted: 'name + options' are needed! options = [] or ".'[{"name":"op","value":"a","quoted":1},{..},..]' }
        unless( $params->{group} && $params->{options} );
    return { 'rc' => 400, 'msg' => "Options Argument must be an empty list or a list of options-objects. Abort! options = ".'[{"name":"op","value":"a","quoted":1},{..},..]' }
        if( ref($params->{options}) eq 'ARRAY' && ref(${$params->{options}}[0]) eq 'HASH' && !${$params->{options}}[0]->{name} && !${$params->{options}}[0]->{value} && !${$params->{options}}[0]->{quoted}
          || ref($params->{options}) eq 'ARRAY' && ${$params->{options}}[0] && ref(${$params->{options}}[0]) ne 'HASH' 
          || ref($params->{options}) ne 'ARRAY' );

    my @group = $config->find_groups({ name => $params->{group} });
    return { 'rc' => 400, 'msg' => "Group name '".$params->{group}."' already exist. Abort!" }
        if( scalar @group );
    return { 'rc' => 500, 'msg' => "Failure during add_group with name: '".$params->{group}." and options: '".$params->{options}."'!" } 
        unless(
            $config->add_group({
                name => $params->{group},
                options => $params->{options}  # options => [{ name => "root-path", value => "value", quoted => 1 }]
            })
        );

    return undef;
}

sub remove {
    my $cgi=shift; my $config=shift; my $params=shift;
    
    return { 'rc' => 400, 'msg' => "No 'params' object{} for method-parameter submitted. Abort!" }
        unless( ref($params) eq 'HASH' );
    return { 'rc' => 400, 'msg' => "Insufficient arguments submitted: 'group' are needed!" }
        unless( $params->{group} );
    
    my @group = $config->find_groups({ name => $params->{group} });
    return { 'rc' => 400, 'msg' => "Group name '".$params->{group}."' not found for removal. Abort!" }
        unless( scalar @group );
    return { 'rc' => 400, 'msg' => "Group '".$group[0]->{name}."' has '".(scalar @{$group[0]->hosts})."' hosts inside. Move or delete hosts before group removal. Abort!" }
        if( scalar @{$group[0]->hosts} > 0 );
    return { 'rc' => 500, 'msg' => "Failure during removal of group '".$group[0]->{name}."'!" }
        unless( $config->remove_groups($group[0]) );

    return undef;
}

sub alter {
    my $cgi=shift; my $config=shift; my $params=shift;
    
    return { 'rc' => 400, 'msg' => "No 'params' object{} for method-parameter submitted. Abort!" }
        unless( ref($params) eq 'HASH' );
    return { 'rc' => 400, 'msg' => "Insufficient arguments submitted: 'group' and ('name' or/and 'options') are required! options = ".'[{"name":"op","value":"a","quoted":1},{..},..]' }
        unless( $params->{group} && ($params->{options} || $params->{name}) );
    return { 'rc' => 400, 'msg' => "Options Argument must be an empty list or a list of options-objects. Abort! options = ".'[{"name":"op","value":"a","quoted":1},{..},..]' }
        if ( defined $params->{options} && ref($params->{options}) eq 'ARRAY' && ref(${$params->{options}}[0]) eq 'HASH' && (!${$params->{options}}[0]->{name} || !${$params->{options}}[0]->{value} || !${$params->{options}}[0]->{quoted})
           || defined $params->{options} && ref($params->{options}) eq 'ARRAY' && ${$params->{options}}[0] && ref(${$params->{options}}[0]) ne 'HASH' );

    my @group = $config->find_groups({ name => $params->{group} });
    return { 'rc' => 400, 'msg' => "Group name '".$params->{group}."' not found for altering. Abort!" }
        unless( scalar @group );
    if( defined $params->{name} ) {
        my @newgroup = $config->find_groups({ name => $params->{name} });
        return { 'rc' => 400, 'msg' => "Target group name '".$params->{name}."' already exists. Abort!" }
            if( scalar @newgroup );
        return { 'rc' => 500, 'msg' => "Failure during add_group with name: '".$params->{group}." and options: '".$group[0]->{options}."'!" }
            unless(
                $config->add_group({
                    name => $params->{name},
                    options => defined $params->{options} ? $params->{options} : [$group[0]->options]
                })
            );
        unless( scalar @{$group[0]->hosts} ) { # group has no hosts
            return { 'rc' => 500, 'msg' => "Failure during removal of group '".$group[0]->{name}."'!" }
                unless( $config->remove_groups($group[0]) );
        } else { # group has hosts
            @newgroup = $config->find_groups({ name => $params->{name} });
            return { 'rc' => 500, 'msg' => "Failure during requesting new created group. Abort!" }
                unless( scalar @newgroup );
            for my $host ( @{$group[0]->hosts} ) {
                return { 'rc' => 500, 'msg' => "Failure during removal of host '".$host->{name}."' in group '".$group[0]->{group}."'!" }
                    unless( $group[0]->remove_hosts($host) );
                return { 'rc' => 500, 'msg' => "Failure during add_host name: '".$host->{name}."' in group: '".$newgroup[0]->{name}."'!" }
                    unless( $newgroup[0]->add_host($host) );
            }
            return { 'rc' => 500, 'msg' => "Failure during removal of group '".$group[0]->{name}."'!" }
                unless( $config->remove_groups($group[0]) );
        }
    } else {   # change only group options (delete 1st all, then add all again)  [{ name => "root-path", value => "value", quoted => 1 }];
        my $optionscount = scalar @{$group[0]->options};
        my $processedOptions = 0;
        for ( @{$group[0]->options} ) {
            $processedOptions++ if $group[0]->remove_options($_);
        }
        return { 'rc' => 500, 'msg' => "Failure during removal of options from group: '".$group[0]->{name}."' !" }
            unless( $optionscount == $processedOptions );
        $optionscount = scalar @{$params->{options}};
        $processedOptions = 0;
        for ( @{$params->{options}} ) {
            $processedOptions++ if $group[0]->add_option($_);
        }
        return { 'rc' => 500, 'msg' => "Failure during adding of options to group: '".$group[0]->{name}."' !" }
            unless( $optionscount == $processedOptions );
    }

    return undef;
}


1;