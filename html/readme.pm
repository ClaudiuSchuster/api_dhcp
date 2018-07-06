package API::html::readme;

use strict; use warnings; use utf8; use feature ':5.10';


sub print { 
    my $cgi = shift;

    my $printReadmeClass = sub { # 'class' 
        if( $_[0] eq 'introduction' ) {
            print "
              <h1>
                <img alt='API ' src='data:image/png;base64,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'>
                Documentation - pxe.mine.io
              </h1>
              <h2>
                Introduction
              </h2>
              <div class='indented'>
                  <hr />
                  <p>
                    The API was created as an JSON Web Service. All of its resources are operated by the central URL: http://$ENV{HTTP_HOST}
                  </p>
                  <p>
                      Goto:
                          <a style='margin-left:10px;' href='#dhcp'>DHCP</a>
                          <span  style='margin:0 10px 0 10px;'>-</span>
                          <a href='#eth'>ETH</a>
                  </p>
                  <h4 id='requests'>
                      Requests
                  </h4>
                  <p>
                      All API request could be either sent as POST or GET requests to the Service-URL, 
                      with the only exception for the 'json' parameter which 'should' be transfered over POST if a method takes use of it.
                  </p>
                  <h4>
                      Responses
                  </h4>
                  <p>
                      If successful, API requests will return an HTTP 200 OK code, as well as a {meta} and a {data} object in response body with content-type 'application/json'.
                  </p>
                  <p>
                    <table border='0'><tbody>
                        <tr>
                            <th>
                                <strong>JSON-Response</strong>
                            </th><th>
                                <strong>Description</strong>
                            </th>
                        </tr>
                        <tr>
                            <td>
                                \"meta\" : { 
                            </td><td>
                                'object{}' with metadata from requested api-execution.
                            </td>
                        </tr>
                        <tr>
                            <td style='padding-left:15px; white-space: nowrap; padding-right:60px;'>
                                \"method\" : null, 
                            </td><td>
                                'string' will contain the 'method' which was executed (if any, not a simple copy of 'method' request parameter).
                            </td>
                        </tr>
                        <tr>
                            <td style='padding-left:15px;'>
                                \"json\" : null, 
                            </td><td>
                                'string' will contain a copy of the 'json' parameter from the request (if it was used by method).
                            </td>
                        </tr>
                        <tr>
                            <td style='padding-left:15px;'>
                                \"rc\" : 200, 
                            </td><td>
                                'integer' with 'response-code' 200 for successful requests, 400 for client based errors, and 500 for internal errors.
                            </td>
                        </tr>
                        <tr>
                            <td style='padding-left:15px;'>
                                \"msg\" : null 
                            </td><td>
                                'string' will be null if successful, else contains the error which happened during method execution.
                            </td>
                        </tr>
                        <tr>
                            <td>
                                }, 
                            </td><td>
                            </td>
                        </tr>
                        <tr>
                            <td>
                                \"data\" : { } 
                            </td><td>
                                'object{}' of requested data which contains one or more objects of specified API methods, e.g. {dhcp}.
                            </td>
                        </tr>
                    </tbody></table>
                  </p>
                  <h4 id='modifyresponse'>
                      Check for successful execution
                  </h4>
                  <p>
                      If returned meta->{method} equals to your requested API-Method and meta->{rc} == 200 the requested API call should be successful.
                  </p>
                  <h4>
                      Modifying responses with query parameters
                  </h4>
                  <p>
                      With the optional query parameter <code>nodata=1</code> an empty response-object of the requested API-Method will be returned inside the {data} object, e.g. {dhcp}. 
                      </br>
                      Can be used to reduce the response data from API calls where only the meta-section is relevant, or to test the examples more readable in the command-line.
                  </p>
                  <hr />
            ";
        } elsif ( $_[0] eq 'endReadme' ) {
            print "
              </div>
              <hr />
            ";
        } else {  # New API-Class
            print "
              </div>
              </br>
              <hr />
              </br>
              <h2 id='$_[0]'>".(uc $_[0])." <code class='method'>method=$_[0] || method=$_[0]/*</code></h2>
              <div class='indented'>
                <hr />
            ";
        }
    };  
    my $printNewMethodTitle = sub { # 'Method', 'Description', 'Note'
        print "
            <h3>$_[1] <code class='method'>method=$_[0]</code> </h3>
        ";
        print "
            <p>
              <em class='wrapper'>
                <span class='left'>
                    Note:
                </span>
                <span class='right'>
                    $_[2]
                </span>
              </em>
            </p>
        " if( defined $_[2] && $_[2] ); # Notes
    };      
    my $printParameterTable = sub { # ['Parameter', 'Type', 'Required', 'Default', 'Info'], [...], ...]
        my @parameter = (    # default parameter
            ['method', 'string', 'true', '', "API method to be executed"],
        );
        my @optParas = (    # default optional parameter
            ['nodata', 'integer', 'false', 0, "Returns an empty response-object if set. View <a href='#modifyresponse'>Introduction</a> for description."],
        );
        if( scalar @_ ) {   # merge defaults with passed parameters
            @parameter = (
                @parameter,
                ['json', 'object{}', 'true', '', "JSON-object{} of method parameters"],
                @_,
                @optParas
            );
        } else {
            @parameter = (
                @parameter,
                @optParas
            );
        }
        print "
            <code>API Parameter:</code>
            <table border='0'>
              <tbody>
                <tr>  
                    <th><strong>Parameter</strong></th>
                    <th><strong>Type</strong></th>
                    <th><strong>Required</strong></th>
                    <th><strong>Default</strong> </th>
                    <th><strong>Info</strong></th>
                </tr>
        ";
        print "
                <tr>
                    <td>$_->[0]</td>
                    <td>$_->[1]</td>
                    <td>$_->[2]</td>
                    <td>$_->[3]</td>
                    <td>$_->[4]</td>
                </tr>
        " for @parameter;
        print "
              </tbody>
            </table>
            <p></p>
        ";
    };
    my $printRequestExample = sub { # 'example'
        print "
            <code>Request Example:</code>
            <pre><code>".API::helpers::trim( $_[0] )."</code></pre>
        ";
    };
    my $printReturnDataTable = sub { # ['Parameter', 'Type', 'Always returned', 'Description' ], [...], ...]
        my @parameter = (    # default parameter
            ['meta', 'object{}', 'yes', "Meta object, view <a href='#requests'>Responses</a> introduction for description."],
            ['data', 'object{}', 'yes', "Data object, view <a href='#requests'>Responses</a> introduction for description."],
        );
        @parameter = ( @parameter, @_ ) if( scalar @_ );  # merge defaults with passed parameters
        print "
            <code>Return data:</code>
            <table border='0'>
              <tbody>
                <tr>  
                    <th><strong>Parameter</strong></th>
                    <th><strong>Type</strong></th>
                    <th><strong>Always returned</strong></th>
                    <th><strong>Description</strong> </th>
                </tr>
        ";
        print "
                <tr>
                    <td>$_->[0]</td>
                    <td>$_->[1]</td>
                    <td>$_->[2]</td>
                    <td>$_->[3]</td>
                </tr>
        " for @parameter;
        print "
              </tbody>
            </table>
            </br>
            <hr />
        ";
    };
    my $printMethod = sub {
        $printNewMethodTitle->( $_[0]->{method}, $_[0]->{title}, $_[0]->{note} );
        $printParameterTable->( @{$_[0]->{parameterTable}} );
        $printRequestExample->( $_[0]->{requestExample} );
        $printReturnDataTable->( @{$_[0]->{returnDataTable}} );
    };
    
    print $cgi->header, $cgi->start_html(
        -title=>"API Documentation - pxe.mine.io",
        -style=>{-code=>"
            body {
              font-family: 'Helvetica';
              margin: 6em 2em 2em 2em;
            }
            h1, h2, h3, h4 {
              font-weight: 600;
            }
            code.method {
              margin: 0 24px 0 24px;
            }
            h1 {
              position: fixed;
              background: -webkit-linear-gradient(top, white 60%, rgba(255,255,255,0));
              background: -moz-linear-gradient(top, white 60%, rgba(255,255,255,0));
              background: -ms-linear-gradient(top, white 60%, rgba(255,255,255,0));
              background: -o-linear-gradient(top, white 60%, rgba(255,255,255,0));
              width: 100%;
              height: 50px;
              padding: 4px 10px 10px 1em;
              left: 0;
              top: 0;
              margin: 0;
            }
            h1 img {
              height: 30px;
              vertical-align: middle;
              margin-bottom: 8px;
            }
            a {
                color: navy;
            }
            hr {
                border: none;
                height: 2px;
                background-color: #140044;
            }
            .wrapper {
                display: table;
                width: 100%;
                height:100%;
            }
            span.left {
                display: table-cell;
                height: 100%;
                white-space: nowrap;
                padding-right: 4px;
                vertical-align: top;
            }
            span.right {
                display: table-cell;
                height: 100%;
                width: 100%;
                vertical-align: top;
            }
            div.indented {
                margin-left: 24px;
            }
            div.indented hr {
                border-top: 1px dotted #140044;
                height: 0px;
                background-color: #fff;
            }
            pre {
                background: #eee;
                padding: 8px;
                border-left: 3px solid #ccc;
                margin-top: 0px;
            }
            table {
                border-collapse: collapse;
                border-spacing: 0;
                overflow: auto;
            }
            table th {
                background-color: #e1ebef;
                border-top: 1px solid #ccc;
                border-bottom: 1px solid #ccc;
                vertical-align: bottom;
            }
            table th, table td {
                padding-right: 16px;
                text-align: left;
                vertical-align: top;
            }
            table tr:nth-child(odd)>td { background-color: #eaeff9; }
            table tr:nth-child(even)>td { background-color: #f3f7fa; }
            table tr:last-child { border-bottom: 1px solid #ccc; }
        "}
    );
    
    $printReadmeClass->('introduction');
    
    $printReadmeClass->('dhcp');
    {

        my $returnObject = ['data:dhcp', 'object{}', 'yes', "Contains the DHCP configuration, view <a href='#dhcp'>method=dhcp</a> for description"];
        
        $printMethod->({
            method          => "dhcp",
            title           => "Get DHCP configuration data",
            note            => "The described return data will be returned with every <code>dhcp/*</code> API-Method.</br>'null' value of a return parameter corresponds to a not defined value on server.",
            parameterTable  => [],
            requestExample  => qq~
curl -d 'method=dhcp' -X POST http://$ENV{HTTP_HOST}
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
        });
        
        $printMethod->({
            method          => "dhcp/restartservice",
            title           => "Restart 'isc-dhcp-server' serivce",
            note            => "",
            parameterTable  => [],
            requestExample  => qq~
curl -d 'nodata=1&method=dhcp/restartservice' -X POST http://$ENV{HTTP_HOST}
            ~,
            returnDataTable => [ $returnObject ],
        });

        $printMethod->({
            method          => "dhcp/addhost",
            title           => "Add a host",
            note            => "",
            parameterTable  => [
                ['json:group', 'string', 'true', '', "name of the existing 'group' where host will be added"],
                ['json:name', 'string', 'true', '', "'name' of the host"],
                ['json:mac', 'string', 'true', '', "'mac'-address of the host"],
            ],
            requestExample  => qq~
curl -d 'nodata=1&method=dhcp/addhost&json={"group":"monsterGroup","name":"powerRig","mac":"11:22:33:44:55:66"}' -X POST http://$ENV{HTTP_HOST}
            ~,
            returnDataTable => [ $returnObject ],
        });

        $printMethod->({
            method          => "dhcp/removehost",
            title           => "Remove a host",
            note            => "",
            parameterTable  => [
                ['json:name', 'string', 'or mac', '', "'name' of the host"],
                ['json:mac', 'string', 'or name', '', "'mac'-address of the host"],
            ],
            requestExample  => qq~
curl -d 'nodata=1&method=dhcp/removehost&json={"name":"powerRig"}' -X POST http://$ENV{HTTP_HOST}
curl -d 'nodata=1&method=dhcp/removehost&json={"mac":"11:22:33:44:55:66"}' -X POST http://$ENV{HTTP_HOST}
            ~,
            returnDataTable => [ $returnObject ],
        });

        $printMethod->({
            method          => "dhcp/alterhost",
            title           => "Alter a host (<code>Change</code> group <code>and/or</code> name <code>and/or</code> mac-address)",
            note            => "If the host will be moved to a group with name <code>(.*-dev|winbios)</code> the host-parameter <code>'vivso'</code> will be set with the origin-group-name to move the host easy back to its original-group.",
            parameterTable  => [
                ['json:name', 'string', 'or mac', '', "'name' of the host"],
                ['json:mac', 'string', 'or name', '', "'mac'-address of the host"],
                ['json:group', 'string', 'and/or newmac|newname', '', "Name of the target 'group' where host will be moved to."],
                ['json:newname', 'string', 'and/or group|newmac', '', "Host will be renamed to this 'newname'."],
                ['json:newmac', 'string', 'and/or group|newname', '', "Mac-Address will be changed to this 'newmac'."],
            ],
            requestExample  => qq~
# Move host to another 'group' (select by 'name' or 'mac'), keep current 'name' and 'mac'
curl -d 'nodata=1&method=dhcp/alterhost&json={"name":"powerRig","group":"megaGroup"}' -X POST http://$ENV{HTTP_HOST}
curl -d 'nodata=1&method=dhcp/alterhost&json={"mac":"11:22:33:44:55:66","group":"megaGroup"}' -X POST http://$ENV{HTTP_HOST}

# Rename host (select by 'name' or 'mac'), keep current 'group' and 'mac'
curl -d 'nodata=1&method=dhcp/alterhost&json={"name":"powerRig","newname":"ultraMiner"}' -X POST http://$ENV{HTTP_HOST}
curl -d 'nodata=1&method=dhcp/alterhost&json={"mac":"11:22:33:44:55:66","newname":"ultraMiner"}' -X POST http://$ENV{HTTP_HOST}

# Alter MAC-Address of host (select by 'name' or 'mac'), keep current 'group' and 'name'
curl -d 'nodata=1&method=dhcp/alterhost&json={"name":"powerRig","newmac":"66:55:44:33:22:11"}' -X POST http://$ENV{HTTP_HOST}
curl -d 'nodata=1&method=dhcp/alterhost&json={"mac":"11:22:33:44:55:66","newmac":"66:55:44:33:22:11"}' -X POST http://$ENV{HTTP_HOST}

# Alter combination of 'name', 'mac' and 'group' together (select by 'name' or 'mac').
curl -d 'nodata=1&method=dhcp/alterhost&json={"name":"powerRig","group":"megaGroup","newname":"ultraMiner","newmac":"66:55:44:33:22:11"}' -X POST http://$ENV{HTTP_HOST}
curl -d 'nodata=1&method=dhcp/alterhost&json={"mac":"11:22:33:44:55:66","group":"megaGroup","newname":"ultraMiner","newmac":"66:55:44:33:22:11"}' -X POST http://$ENV{HTTP_HOST}
curl -d 'nodata=1&method=dhcp/alterhost&json={"name":"powerRig","group":"megaGroup","newname":"ultraMiner"}' -X POST http://$ENV{HTTP_HOST}
curl -d 'nodata=1&method=dhcp/alterhost&json={"mac":"11:22:33:44:55:66","group":"megaGroup","newname":"ultraMiner"}' -X POST http://$ENV{HTTP_HOST}
curl -d 'nodata=1&method=dhcp/alterhost&json={"name":"powerRig","group":"megaGroup","newmac":"66:55:44:33:22:11"}' -X POST http://$ENV{HTTP_HOST}
curl -d 'nodata=1&method=dhcp/alterhost&json={"mac":"11:22:33:44:55:66","group":"megaGroup","newmac":"66:55:44:33:22:11"}' -X POST http://$ENV{HTTP_HOST}
curl -d 'nodata=1&method=dhcp/alterhost&json={"name":"powerRig","newname":"ultraMiner","newmac":"66:55:44:33:22:11"}' -X POST http://$ENV{HTTP_HOST}
curl -d 'nodata=1&method=dhcp/alterhost&json={"mac":"11:22:33:44:55:66","newname":"ultraMiner","newmac":"66:55:44:33:22:11"}' -X POST http://$ENV{HTTP_HOST}
            ~,
            returnDataTable => [ $returnObject ],
        });

        $printMethod->({
            method          => "dhcp/addgroup",
            title           => "Add a group",
            note            => "",
            parameterTable  => [
                ['json:group', 'string', 'true', '', "name of the new 'group'"],
                ['json:options', 'array[]', 'true', '', qq~array[] of config 'option'-objects{} for the group</br>[{"name":"op","value":"a","quoted":1},{..},..]~],
            ],
            requestExample  => qq~
curl -d 'nodata=1&method=dhcp/addgroup&json={"group":"monsterGroup","options":[]}' -X POST http://$ENV{HTTP_HOST}
curl -d 'nodata=1&method=dhcp/addgroup&json={"group":"monsterGroup","options":[{"name":"foo","value":"bar","quoted":1}]}' -X POST http://$ENV{HTTP_HOST}
            ~,
            returnDataTable => [ $returnObject ],
        });

        $printMethod->({
            method          => "dhcp/removegroup",
            title           => "Remove a group",
            note            => "The group must be empty (move/remove hosts first).",
            parameterTable  => [
                ['json:group', 'string', 'true', '', "name of the 'group' which will be removed"],
            ],
            requestExample  => qq~
curl -d 'nodata=1&method=dhcp/removegroup&json={"group":"monsterGroup"}' -X POST http://$ENV{HTTP_HOST}
            ~,
            returnDataTable => [ $returnObject ],
        });

        $printMethod->({
            method          => "dhcp/altergroup",
            title           => "Alter a group (<code>Change</code> name <code>and/or</code> options)",
            note            => "",
            parameterTable  => [
                ['json:group', 'string', 'true', '', "name of the 'group' to alter"],
                ['json:name', 'string', 'or/and options', '', "rename the group to this new 'name'"],
                ['json:options', 'array[]', 'or/and name', '', qq~replace all 'options' of the group with this 'options'</br>[{"name":"op","value":"a","quoted":1},{..},..]~],
            ],
            requestExample  => qq~
# Rename group and keep current options.
curl -d 'nodata=1&method=dhcp/altergroup&json={"group":"megaGroup","name":"monsterGroup"}' -X POST http://$ENV{HTTP_HOST}

# Rename group and set new options. (In example all currently existing options will be deleted)
curl -d 'nodata=1&method=dhcp/altergroup&json={"group":"megaGroup","name":"monsterGroup","options":[]}' -X POST http://$ENV{HTTP_HOST}

# Replace the options and keep the current name.
curl -d 'nodata=1&method=dhcp/altergroup&json={"group":"megaGroup","options":[{"name":"foo","value":"bar","quoted":1}]}' -X POST http://$ENV{HTTP_HOST}
            ~,
            returnDataTable => [ $returnObject ],
        });

    }
    
    $printReadmeClass->('eth');
    {

        # my $returnObject = ['data:eth', 'object{}', 'yes', "Contains ETH Data, view <a href='#eth'>method=eth</a> for description"];

        # $printMethod->({
            # method          => "eth",
            # title           => "Get ETH data",
            # note            => "What a cool Note!",
            # parameterTable  => [],
            # requestExample  => qq~Do something cool~,
            # returnDataTable => [ $returnObject ],
        # });

        1;
    }
    
    $printReadmeClass->('endReadme');
    
    print $cgi->end_html;
}


1;