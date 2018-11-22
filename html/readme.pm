package API::html::readme;

use strict; use warnings; use utf8; use feature ':5.10';

## Load our readme modules
use html::readme::print;

sub print { 
    my $cgi = shift;
    
    API::html::readme::print::ReadmeClass('introduction',$cgi,' - api_isc-dhcp',[]);  # ['dhcp','mine','eth']
    
    
    API::html::readme::print::ReadmeClass([
        {
            readmeClass  => 'dhcp',
            returnObject => ['data:dhcp', 'object{}', 'yes', "Contains the DHCP configuration, view <a href='#dhcp || dhcp.get'>method:dhcp</a> for description"]
        },
        {
            method          => "dhcp || dhcp.get",
            title           => "Get DHCP configuration data",
            note            => "The described return data will be returned with every <code>dhcp.*</code> API-Method.</br>'null' value of a return parameter corresponds to a not defined value on server.",
            parameterTable  => [],
            requestExample  => qq~
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp"}'
            ~,
            returnDataTable => [
                ['data:dhcp', 'object{}', 'yes', "Contains the DHCP configuration if successful"],
                ['data:dhcp:status', 'object{}', 'yes', "Contains status information about 'isc-dhcp-service'"],
                ['data:dhcp:status:active', 'bool', 'yes', "Running status of 'isc-dhcp-server'."],
                ['data:dhcp:status:etimes', 'integer', 'yes || null', "Seconds since 'isc-dhcp-server' start."],
                ['data:dhcp:status:lstart', 'string', 'yes || null', "Timestamp string of 'isc-dhcp-server' start."],
                ['data:dhcp:groups', 'object{}', 'no', "Contains groupname-named objects for all DHCP groups. Not returned if DHCP has no groups."],
                ['data:dhcp:groups:*', 'object{}', 'yes', "Groupname-named object for each group."],
                ['data:dhcp:groups:*:options', 'object{}', 'no', "Contains 'strings' of the group option parameters. Not returned if group has no options!"],
                ['data:dhcp:groups:*:options:*', 'string', 'yes', "Option-named strings of each group-option. More individual not listed options possible!"],
                ['data:dhcp:groups:*:options:ipxe.san-filename', 'string', 'no', "'Boot-Image' name, e.g. 'amd-dev'"],
                ['data:dhcp:groups:*:options:ipxe.username', 'string', 'no', "Mining authentication username for pool. (email-address)"],
                ['data:dhcp:groups:*:options:ipxe.password', 'string', 'no', "Mining account address."],
                ['data:dhcp:groups:*:options:iscsi-initiator-iqn', 'string', 'no', "Mining pool protocol, e.g. 'stratum1+tcp://'"],
                ['data:dhcp:groups:*:options:ipxe.reverse-username', 'string', 'no', "PoolIP1:Port1 address, e.g. 'eth-eu1.nanopool.org:9999'"],
                ['data:dhcp:groups:*:options:ipxe.reverse-password', 'string', 'no', "PoolIP2:Port2 address, e.g. 'eth-eu2.nanopool.org:9999'"],
                ['data:dhcp:groups:*:options:vendor-class-identifier', 'string', 'no', "Unused, free dhcp option which can be used in ipxe."],
                ['data:dhcp:groups:*:options:root-path', 'string', 'no', "Unused, free dhcp option which can be used in ipxe."],
                ['data:dhcp:groups:*:hosts', 'object{}', 'no', "Contains hostname-named objects for all hosts in this group. Not returned for empty groups!"],
                ['data:dhcp:groups:*:hosts:*', 'object{}', 'yes', "Hostname-named configuration object for each existing host in this group."],
                ['data:dhcp:groups:*:hosts:*:name', 'string', 'yes', "Hostname of the host."],
                ['data:dhcp:groups:*:hosts:*:hardware_address', 'string', 'yes', "Hardware/Mac address of the host."],
                ['data:dhcp:groups:*:hosts:*:vivso', 'string', 'yes || null', "Contains the origin-groupname if host was moved to a <code>(.*-dev|winbios)</code> named group."],
                ['data:dhcp:groups:*:hosts:*:lease', 'object{}', 'no', "Contains the lease information for the host. Not returned for hosts without lease!"],
                ['data:dhcp:groups:*:hosts:*:lease:state', 'string', 'yes', "State of the lease, 'active' or 'free.'"],
                ['data:dhcp:groups:*:hosts:*:lease:ip_address', 'string', 'yes', "IP-Address of the lease."],
                ['data:dhcp:groups:*:hosts:*:lease:client_hostname', 'string', 'yes || null', "Client-Hostname if it was transmitted from host."],
                ['data:dhcp:groups:*:hosts:*:lease:starts', 'integer', 'yes ', "Lease start unix-timestamp."],
                ['data:dhcp:groups:*:hosts:*:lease:ends', 'integer', 'yes', "Lease end unix-timestamp."],
                ['data:dhcp:leases', 'object{}', 'no', "Contains IP-Address-named objects of all dhcp leases. Not returned if DHCP has no leases."],
                ['data:dhcp:leases:*', 'object{}', 'yes', "IP-Address-named object for each lease."],
                ['data:dhcp:leases:*:state', 'string', 'yes', "State of the lease, 'active' or 'free'."],
                ['data:dhcp:leases:*:client_hostname', 'string', 'yes || null', "Client-hostname if it was transmitted from host."],
                ['data:dhcp:leases:*:hardware_address', 'string', 'yes', "Hardware/Mac address of the lease."],
                ['data:dhcp:leases:*:starts', 'integer', 'yes', "Lease start unix-timestamp."],
                ['data:dhcp:leases:*:ends', 'integer', 'yes', "Lease end unix-timestamp."],
                ['data:dhcp:leases:*:host', 'object{}', 'no', "Contains the host configuration for this lease. Not returned if lease has no host!"],
                ['data:dhcp:leases:*:host:name', 'string', 'yes', "Configured 'name' from associated host."],
                ['data:dhcp:leases:*:host:group', 'string', 'yes', "Groupname from associated host."],
                ['data:dhcp:leases:*:host:vivso', 'string', 'yes || null', "Contains the origin-groupname if associated host was moved to a <code>(.*-dev|winbios)</code> named group."],
            ],
        },
        {
            method          => "dhcp.service.restart",
            title           => "Restart 'isc-dhcp-server' serivce",
            note            => "",
            parameterTable  => [],
            requestExample  => qq~
// Request
curl http://$ENV{HTTP_HOST} -d '{"nodata":1,"method":"dhcp.service.restart"}'

// Result
{
   "meta" : {
      "msg" : null,
      "rc" : 200,
      "postdata" : {
         "method" : "dhcp.service.restart",
         "nodata" : 1
      },
      "method" : "dhcp.service.restart"
   },
   "data" : {
      "dhcp" : {}  /* Contains (without nodata=1) the isc-dhcp-server service status, uptime and configuration.
   }                  View <a href='#dhcp || dhcp.get'>method:dhcp</a> for detailed description. */
}
            ~,
            returnDataTable => [ 'returnObject' ],
        },
        {
            method          => "dhcp.host.add",
            title           => "Add a host",
            note            => "",
            parameterTable  => [
                ['params:group', 'string', 'true', '', "name of the existing 'group' where host will be added"],
                ['params:name', 'string', 'true', '', "'name' of the host"],
                ['params:mac', 'string', 'true', '', "'mac'-address of the host"],
            ],
            requestExample  => qq~
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.host.add","params":{"group":"monsterGroup","name":"powerRig","mac":"11:22:33:44:55:66"}}'
            ~,
            returnDataTable => [ 'returnObject' ],
        },
        {
            method          => "dhcp.host.remove",
            title           => "Remove a host",
            note            => "",
            parameterTable  => [
                ['params:name', 'string', 'or mac', '', "'name' of the host"],
                ['params:mac', 'string', 'or name', '', "'mac'-address of the host"],
            ],
            requestExample  => qq~
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.host.remove","params":{"name":"powerRig"}}'
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.host.remove","params":{"mac":"11:22:33:44:55:66"}}'
            ~,
            returnDataTable => [ 'returnObject' ],
        },
        {
            method          => "dhcp.host.alter",
            title           => "Alter a host (<code>Change</code> group <code>and/or</code> name <code>and/or</code> mac-address)",
            note            => "Altering of MAC-Address may require further manual Bind DNS-Zone reconfiguration! </br>If the host will be moved to a group with name <code>(.*-dev|winbios)</code> the host-parameter <code>'vivso'</code> will be set with the origin-group-name to move the host easy back to its original-group.",
            parameterTable  => [
                ['params:name', 'string', 'or mac', '', "'name' of the host"],
                ['params:mac', 'string', 'or name', '', "'mac'-address of the host"],
                ['params:group', 'string', 'and/or newmac|newname', '', "Name of the target 'group' where host will be moved to."],
                ['params:newname', 'string', 'and/or group|newmac', '', "Host will be renamed to this 'newname'."],
                ['params:newmac', 'string', 'and/or group|newname', '', "Mac-Address will be changed to this 'newmac'."],
            ],
            requestExample  => qq~
# Move host to another 'group' (select by 'name' or 'mac'), keep current 'name' and 'mac'
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.host.alter","params":{"name":"powerRig","group":"megaGroup"}}'
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.host.alter","params":{"mac":"11:22:33:44:55:66","group":"megaGroup"}}'

# Rename host (select by 'name' or 'mac'), keep current 'group' and 'mac'
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.host.alter","params":{"name":"powerRig","newname":"ultraMiner"}}'
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.host.alter","params":{"mac":"11:22:33:44:55:66","newname":"ultraMiner"}}'

# Alter MAC-Address of host (select by 'name' or 'mac'), keep current 'group' and 'name'
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.host.alter","params":{"name":"powerRig","newmac":"66:55:44:33:22:11"}}'
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.host.alter","params":{"mac":"11:22:33:44:55:66","newmac":"66:55:44:33:22:11"}}'

# Alter combination of 'name', 'mac' and 'group' together (select by 'name' or 'mac').
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.host.alter","params":{"name":"powerRig","group":"megaGroup","newname":"ultraMiner","newmac":"66:55:44:33:22:11"}}'
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.host.alter","params":{"mac":"11:22:33:44:55:66","group":"megaGroup","newname":"ultraMiner","newmac":"66:55:44:33:22:11"}}'
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.host.alter","params":{"name":"powerRig","group":"megaGroup","newname":"ultraMiner"}}'
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.host.alter","params":{"mac":"11:22:33:44:55:66","group":"megaGroup","newname":"ultraMiner"}}'
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.host.alter","params":{"name":"powerRig","group":"megaGroup","newmac":"66:55:44:33:22:11"}}'
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.host.alter","params":{"mac":"11:22:33:44:55:66","group":"megaGroup","newmac":"66:55:44:33:22:11"}}'
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.host.alter","params":{"name":"powerRig","newname":"ultraMiner","newmac":"66:55:44:33:22:11"}}'
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.host.alter","params":{"mac":"11:22:33:44:55:66","newname":"ultraMiner","newmac":"66:55:44:33:22:11"}}'
            ~,
            returnDataTable => [ 'returnObject' ],
        },
        {
            method          => "dhcp.group.add",
            title           => "Add a group",
            note            => "",
            parameterTable  => [
                ['params:group', 'string', 'true', '', "name of the new 'group'"],
                ['params:options', 'array[]', 'true', '', qq~array[] of config 'option'-objects{} for the group</br>[{"name":"op","value":"a","quoted":1},{..},..]~],
            ],
            requestExample  => qq~
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.group.add","params":{"group":"monsterGroup","options":[]}}'
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.group.add","params":{"group":"monsterGroup","options":[{"name":"foo","value":"bar","quoted":1}]}}'
            ~,
            returnDataTable => [ 'returnObject' ],
        },
        {
            method          => "dhcp.group.remove",
            title           => "Remove a group",
            note            => "The group must be empty (move/remove hosts first).",
            parameterTable  => [
                ['params:group', 'string', 'true', '', "name of the 'group' which will be removed"],
            ],
            requestExample  => qq~
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.group.remove","params":{"group":"monsterGroup"}}'
            ~,
            returnDataTable => [ 'returnObject' ],
        },
        {
            method          => "dhcp.group.alter",
            title           => "Alter a group (<code>Change</code> name <code>and/or</code> options)",
            note            => "",
            parameterTable  => [
                ['params:group', 'string', 'true', '', "name of the 'group' to alter"],
                ['params:name', 'string', 'or/and options', '', "rename the group to this new 'name'"],
                ['params:options', 'array[]', 'or/and name', '', qq~replace all 'options' of the group with this 'options'</br>[{"name":"op","value":"a","quoted":1},{..},..]~],
            ],
            requestExample  => qq~
# Rename group and keep current options.
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.group.alter","params":{"group":"megaGroup","name":"monsterGroup"}}'

# Rename group and set new options. (In example all currently existing options will be deleted)
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.group.alter","params":{"group":"megaGroup","name":"monsterGroup","options":[]}}'

# Replace the options and keep the current name.
curl http://$ENV{HTTP_HOST} -d '{"method":"dhcp.group.alter","params":{"group":"megaGroup","options":[{"name":"foo","value":"bar","quoted":1}]}}'
            ~,
            returnDataTable => [ 'returnObject' ],
        }
    ]);
    
    
    # API::html::readme::print::ReadmeClass([
        # {
            # readmeClass  => 'mine',
            # returnObject => ['data:mine', 'object{}', 'yes', "Contains Mine Data, view <a href='#eth'>method: mine</a> for description"]
        # },
        # {
            # method          => "mine",
            # title           => "Get Mine data",
            # note            => "What a cool Note!",
            # parameterTable  => [],
            # requestExample  => qq~Do something cool~,
            # returnDataTable => [ 'returnObject' ],
        # },
        # {
            # method          => "mine.method",
            # title           => "Do mine.method",
            # note            => "What a cool Note!",
            # parameterTable  => [],
            # requestExample  => qq~
# curl http://$ENV{HTTP_HOST} -d '{"method":"mine.method"}'
            # ~,
            # returnDataTable => [ 'returnObject' ],
        # }
    # ]);
    
    
    API::html::readme::print::ReadmeClass('endReadme',$cgi);
}


1;