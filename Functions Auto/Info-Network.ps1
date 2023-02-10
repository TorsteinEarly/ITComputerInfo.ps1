



#===========================================================================
# Network
# Overview: Get all mac addresses, iterate over mac addresses to get IPAddress/VLANs
#===========================================================================
# Get Adapter info. used for both network and network test
Function Get-SVCNetAdapterInfo {
    Get-WmiObject win32_networkadapterconfiguration  |
    Where-Object { $PSitem.description -like "*anyconnect*" -or (
            $PSitem.description -notlike "*Miniport*" -and
            $PSitem.description -notlike "*Kernel Debug*" -and
            $PSitem.description -notlike "*Tunnel*" -and
            $PSitem.description -notlike "*Bluetooth*" -and
            $PSitem.description -notlike "*Virtual*" -and
            $Null -notlike $PSitem.Macaddress)
    } |    Select-Object description, caption, macaddress, dnsdomain, dhcpenabled,
    DNSServerSearchOrder, DHCPServer, DefaultIPGateway,
    @{Name = "IPAddress"; Expression = { $PSitem.IPAddress[0] } },
    @{Name = "SubnetMask"; Expression = { $PSitem.IPSubnet[0] } },
    @{Name = "InterfaceMetric"; Expression = { $PSitem.IPConnectionMetric } } |
    Sort-Object -Property InterfaceMetric
}



#=============================================
# Get info for net adapters
#=============================================
function Get-SVCNetworkInfo {
    $Output = [pscustomobject]@{}
    $Header = 1
    $NetAdapters = Get-SVCNetAdapterInfo

    $WIFIInfo = netsh wlan show interface

    if ( $WIFIInfo -like "*not running.*") {
        $Header ++
        $Params = @{
            membertype = "NoteProperty"
            Name       = "Header$Header"
            value      = $( "Wi-Fi adapter not present." + [System.Environment]::NewLine )
        }
        $Output | Add-Member  @Params

    }
    else {
        $WIFIMac = (netsh wlan show interface |
            Select-String "Physical Address").tostring().substring(29, 17)

        if ($WIFIInfo -like "*disconnected*") {
            $SSID = "Disconnected"
        }
        Else {
            $SSID = ( ( ( netsh wlan show interface |
                        Select-String ssid | Select-Object -First 1 ) -split ':' )[1]
            ).trim()

            if ( $SSID -in "MySVC", "SVC", "ECB", "SVC-Guest") {
                $Text = "Connected to $($SSID) Wireless Network!!! "
                $Text += "Please connect only to the Skagit wireless network on Skagit owned equipment "
                $Text += "to ensure you have access to Skagit network resources.`n`n"
                Write-Results -color "Red" -Bold -header "CRITICAL: " -text $Text
                $WPFbackNetwork.background = $FormYellow
            }
        }
    }


    # Get a unique list of MAC Addresses to iterate through.
    $MACAddresses = $netadapters.macaddress | Select-Object -Unique

    #=============================================================
    # ForEach MAC Addresses.
    # We are essentially identifying physical NICs by their MAC.
    #=============================================================
    foreach ($MACAddress in $MACAddresses) {

        if ($Output) {
            # Good
        }
        else {
            $Output = [pscustomobject]@{}
        }


        $NetworkHeading = $(
            if ($MacAddress -like $WIFIMac) {
                "Connected WiFi Network: $SSID"
            }
            else {
                "Local Area Network"
            }
        )

        $Heading ++
        $Output | Add-Member -MemberType NoteProperty -Name "Header$Heading" -Value $NetworkHeading
        $Output | Add-Member -MemberType NoteProperty -Name "MAC Address" -Value $MACAddress
        # Next property will be:
        # description if no IP, or
        # IP address
        # Depending on the following If/else statements

        # Get the IP Address or VLANs for this MAC.
        $( $VLANsOnThisMACAddress = $NetAdapters  |
            Where-Object { $PSitem.macaddress -like $Macaddress }
        )
        If ($VLANsOnThisMACAddress.count -gt 1) {
            $VLAN = $True
        }
        else {
            $VLAN = $False
        }



        #=============================================================
        # ForEach IP on this MAC.
        #=============================================================
        $VLANsOnThisMACAddress | ForEach-Object {

            if ($output) {} else { $Output = [pscustomobject]@{} }

            $Description = "  Description : "
            $DescriptionLength = $Description.length
            $DescriptionWords = $PSitem.description.split(" ")
            $DescriptionWords | ForEach-Object {
                if ($Descriptionlength -gt 25) {
                    $description += "`n   Descr cont : $PSitem "
                    $Descriptionlength = 16
                }
                else {
                    $description += "$PSItem "
                    $Descriptionlength += $PSitem.length
                }
            }

            if ($Null -like $PSitem.IPaddress) {
                #=============================================================
                # This adapter disconnected or is a system adapter.
                # There may be other adapters in the array that are enabled.
                #=============================================================

                #Give it an description so it looks less innocuous.
                $Header++
                $Params = @{
                    membertype = "NoteProperty"
                    Name       = "Header$Header"
                    value      = $Description
                }
                $Output | Add-Member  @Params

                $Output  # Output the object
                Clear-Variable Output  # clear the object so we can add the same names to it
            }
            else {
                #=============================================================
                # There Is an IP address. Get it's info.
                #=============================================================
                $( #Check for private assigned IP address
                    # Get first 2 octet of the IP address
                    $IPSubScript = $(
                        $($PSitem.ipaddress).Split(".") |
                        Select-Object -First 2
                    ) -join "."

                    # Check for self assigned IP address/DHCP issues
                    if ($IPSubScript.tostring() -in $SelfAssignedRange -and
                        $PSitem.subnetmask.tostring() -like "255.255.0.0" ) {
                        Write-Results -color "red" -Bold -header "CRITICAL: "  -text "IP Address on $MACAddress is within the self assigned range.
    This likley indicates an incorrect VLAN on the switch port (this machine only), or a DHCP Server issue (would also effect other machines upon restart or DHCP lease expiration/renewal).`n`n"
                    }
                ) # End check for private assigned IP address

                $( # Check for Printer subnet IP address
                    # Get first 3 octet of the IP address
                    $IPSubScript = $(
                        $($PSitem.ipaddress).Split(".") |
                        Select-Object -First 3
                    ) -join "."

                    # Check for printer subnet
                    if ($IPSubScript.tostring() -like "10.209.209" ) {
                        Write-Results -color "red" -Bold -header "CRITICAL: " -text "IP Address on $MACAddress is on the 10.209.209 printer subnet. Network will be unavilable.
Check that the computer network cable is plugged into the right port. If it is, configure the network switch port for the correct VLAN. `n`n"
                    }
                ) # End check for printer subnet IP address

                # If this adapter/vlan has an IP address assigned
                $DHCPServer = $PSitem.dhcpserver
                switch ($PSitem.dhcpenabled) {
                    True {
                        $DHCPHeader = "  DHCP Server"
                        $DHCPStatus = $DHCPServer
                    }
                    False {
                        $DHCPHeader = "  No DHCP"
                        $DHCPStatus = "Static IP Address"
                    }
                    default {
                        $DHCPHeader = "  No DHCP"
                        $DHCPStatus = "[DHCP Error]"
                    }
                }


                $IPHeader = if ( $VLAN -like $True) {
                    " VLAN IP Adrs"  # Indent to show that there will be multiple IPs on this adapter
                }
                else {
                    "IP Address"
                }

                $EmpStuNetwork = switch ($PSitem.dnsdomain) {
                    "skagit.edu" { "[SVC Employee]" }
                    "mv.skagit.edu" { "[SVC Employee]" }
                    "Mysvc.skagit.edu" { "[SVC Student]" }
                    "WiFI.skagit.edu" { "[SVC WiFI]" }
                    "ilo.skagit.edu" { "[Mgmt NET]" }
                    { $DHCPStatus -like "Static IP Address" } { "[Static IP Hides This]" }
                    default { "[Unknown NET]" }
                }

                $DNSDomainName = $PSitem.dnsdomain + " $EmpStuNetwork"

                $DNSServers = $( If ($Null -like $PSitem.DNSServerSearchOrder) {
                        "  DNS Server  : Undefined"
                    }
                    else {
                        "  DNS Server1 : " + $PSitem.DNSServerSearchOrder[0]
                        if ($Null -like $PSitem.dnsserversearchorder[1] ) {} else {
                            "`n  DNS Server2 : $($PSitem.dnsserversearchorder[1])"
                        }
                    }
                )


                # Add VLAN info to the output object.
                $Output | Add-Member -MemberType NoteProperty -Name  $IPHeader -Value  $PSitem.IPAddress
                $Output | Add-Member -MemberType NoteProperty -Name  $DHCPHeader -Value $DHCPStatus
                $Header ++
                $Output | Add-Member -MemberType NoteProperty -Name "Header$Header" -Value $Description
                $Output | Add-Member -MemberType NoteProperty -Name "  Dft Gateway" -Value  $PSItem.DefaultIPGateway
                $Output | Add-Member -MemberType NoteProperty -Name "  Subnet Mask" -Value  $PSitem.SubnetMask
                $Output | Add-Member -MemberType NoteProperty -Name "  Int Metric"   -Value $PSitem.InterfaceMetric
                $Output | Add-Member -MemberType NoteProperty -Name "  DNS Domain"  -Value $($DNSDomainName).trim(" ")
                $Header ++
                $Output | Add-Member -MemberType NoteProperty -Name  "Header$Header"  -Value $DNSServers
                $Output  # Output the object
                Clear-Variable Output  # remove the object so we can recreate it again at the start of the loop

            } # Else ($Null -like $PSitem.IPaddress)  (There is an IP. Process the NIC)

        } # For Each VLAN or IP on this MAC
    } # For Each MAC Address

    # Warning for static IP
    if ($WPFtxtNetworkInfo.text -like "*Static*") {
        $Text = "IP Address is statically assigned. "
        $Text += "IT typically uses DHCP to dynamically assign or reserve IP addresses. `n`n"
        Write-Results -color 'purple' -bold -header 'NOTE: ' -text $Text
        $WPFbackNetwork.background = $FormYellow

    }
}  # End Network



