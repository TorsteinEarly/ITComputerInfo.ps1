
#===========================================================================
# Network Testing
# Overview: Get all mac addresses, iterate over mac addresses to test network
#===========================================================================
# For network testing




# Sets form to look like the tool is running
$WPFbacknetwork.Background = "#FFFDF9A2"
#  $WPFbtnTestNetwork.Foreground = "white"
#  $WPFbtnTestNetwork.Background = "red"
$WPFbtnTestNetwork.Content = "Running Network Test"
$WPFWindowITComputerInfo.title = "Testing Network... This could take several minutes: Please do not close this window. "

function Invoke-NTestCancel {
    # $WPFbtnTestNetwork.Foreground = "black"
    # $WPFbtnTestNetwork.Background = "#FFDDDDDD"
    $WPFbtnTestNetwork.Content = "Run Network Test"
    $WPFWindowITComputerInfo.title = "SVC IT Computer Info"
}


if ( $Script:NetworkTestResults ) {
    $Text = "Network test has already run and results are available to copy to clipboard via the the Copy Info button. `n`n"
    $Text += "        Do you want to test again?`n`n"
    $Text += "        Yes: Re-Run Testing.`n`n"
    $Text += "        No: Cancel."
    $RunTest = $shell.popup($Text, 0, "Network Testing:", $ShowOnTop + $Icon.Question + $Buttons.YesNo)

    Switch ($clickedButton.$RunTest) {
        'Yes' { ' Run the network test' }
        'No' { Invoke-NTestCancel; return }
    }
}
else {

    $Text = "This tool can provide basic network info and troublshooting steps in the event of a network outage. `n`n"
    $Text += "Run as directed by a Help Desk Technician, or in advance of contacting the Help Desk for help.  `n`n"
    $Text += "        Do you want to continue?"

    $RunTest = $shell.popup($text, 0, "Network Testing:", $ShowOnTop + $Icon.Question + $Buttons.YesNo)

    Switch ($clickedButton.$RunTest) {
        'OK' { ' Run the network test' }
        'No' { Invoke-NTestCancel; return }
    }
} # End if test has previously run

# Prep

# The fastest ping in the west
function Test-PSOnePing {
    param
    (
        # Computername or IP address to ping
        [Parameter(Mandatory, ValueFromPipeline)]
        [string[]]
        $ComputerName,

        # Timeout in milliseconds
        [int]
        [ValidateRange(100, 50000)]
        $Timeout = 2000
    )

    begin {
        $Online = @{
            Name       = 'Online'
            Expression = { $_.Status -eq 'Success' }
        }
        $obj = New-Object System.Net.NetworkInformation.Ping
    }

    process {
        $ComputerName |
        ForEach-Object {
            $obj.Send($_, $timeout) |
            Select-Object -Property $Online, Status, Address |
            Add-Member -MemberType NoteProperty -Name Name -Value $_ -PassThru
        }
    }
} # end ping function


$SelfAssignedRange = 169.254, 169.255
$SkippedIPs = @()


# Begin: Get adapter info

$WPFtxbResults.Document.Blocks.Clear()  # Clear results box before we populate it with test data.

$NetAdapters = Get-SVCNetAdapterInfo

$WIFIInfo = netsh wlan show interface

if ( $WIFIInfo -like "*not running.*") { "Nothing to see here" }
else {
    $WIFIMac = (netsh wlan show interface |
        Select-String "Physical Address").tostring().substring(29, 17)

    if ($WIFIInfo -like "*disconnected*") { $SSID = "Disconnected" } Else {
        $SSID = ( ( ( netsh wlan show interface |
                    Select-String ssid | Select-Object -First 1 ) -split ':' )[1] ).trim()
    }
}

# Get a unique list of MAC Addresses to iterate through.
$MACAddresses = $netadapters.macaddress | Select-Object -Unique

#==================================================================================================#
# Iterate through the MAC Addresses. We are essentially identifying physical NICs by their MAC.
#==================================================================================================#
foreach ($MACAddress in $MACAddresses) {
    write-results -bold -header "Testing connection(s) for adapter:" -text " $Macaddress `n`n"

    # Get the IP Address or VLANs for this MAC.
    $( $VLANsOnThisMACAddress = $NetAdapters  |
        Where-Object { $PSitem.macaddress -like $Macaddress }
    )

    $VLANCount = 0 # for testing for physical adapters with attached vlans

    #==================================================================================================#
    # Process the IP(s) on this MAC.
    #==================================================================================================#
    $VLANsOnThisMACAddress |  ForEach-Object {

        # Clear value before testing.
        $NetworkFailure = $False

        if ($VLANsOnThisMACAddress.count -gt 1) {
            $VLANCount ++ #iterate the counter for each vlan on this mac address
        }

        #=============================================#
        # IP Address checks
        #=============================================#
        if ($Null -like $PSitem.IPaddress) {
            # If the physical adapter on a vlan enabled adapter, skip this.

            if ($VLANCount -eq 1 -and
                $VLANsOnThisMACAddress.count -gt 1) {
                $NetworkFailure = "Skip"
                # this is the phsical address of a VLAN enabled adapter. It does not have an IP.
            }
            else {
                # This is either a physical adapter or a virtual VLAN adapter.
                # It should have an IP.
                # Check to see if it is a Wifi adapter that is disconnected.

                if ($WIFIMac) {
                    if ($MacAddress -like $WIFIMac) {
                        # This is the Wi-Fi Adapter
                        $Text = "Wi-Fi Adapter $MACAddress does not have an IP Address. `n"

                        $Text += "This is normal if the Laptop is also connected to LAN: To Test your Wi-Fi adapter, "
                        $Text += "disconnect the Ethernet cable from the laptop, wait a few seconds, confirm that you "
                        $Text += "are connected to a wireless network (Skagit if on campus), confirm that the tool is "
                        $Text += "ready by clicking the Reload Info button (Tool is ready when the WIFI adapter shows "
                        $Text += "an IP address), then click the Test Network button again.`n"

                        $Text += "If unable to connect to the wireless network, attempt to connect with another device "
                        $Text += "to see if this device is having an issue.`n"

                        $Text += "If multiple devices cannot connect to the wireless network then there may be a wireless "
                        $Text += "network issue: contact the Networking team if the network in question is an SVC wireless network. `n`n"

                        Write-Results -color "Red" -header "WARNING - IP Address Check: " -text $Text

                    }
                    else {
                        # Wi-Fi adapter exists, but this is the LAN adapter
                        $Text = "LAN Adapter $MACAddress does not have an IP Address. `n"
                        $Text += "This is normal if the Laptop is connected to Wi-Fi and disconnected from the LAN.`n"
                        $Text += "If you think you should be connected to the LAN, check for: Ethernet cable Disconnected from this Computer.`n"
                        $Text += "If the cable is connected, check that it is plugged into an active wall jack.`n"
                        $Text += "If no wall jacks are active, or if multiple computers report this failure, "
                        $Text += "check for network Switch off/amber lights/disconnected/port dissabled.`n`n"
                        Write-Results  -color "Red" -header "WARNING - IP Address Check: " -text $Text

                    } # end else if macadress like wifi
                }
                else {
                    # Wi-Fi adapter does not exist: LAN should have an IP address.
                    $Text = " - IP Address Check: Adapter $MACAddress does not have an IP Address. `n"
                    $Text += "Check for: Ethernet cable Disconnected from this Computer. `n"
                    $Text += "If the cable is connected, check that it is plugged into an active wall jack. `n"
                    $Text += "If no wall jacks are active, or if multiple computers report this failure, "
                    $Text += "check for network Switch off/amber lights/disconnected/port dissabled.`n`n"
                    Write-Results -color "Red" -header "FAILURE" -text $Text

                } # end if wifi mac exists

                $NetworkFailure = $True  # No IP Address: Don't continue testing this adapter. Other adapters will still continue.
            } # End IP Address Missing error

        } # end if null IP address
        else {
            # There is an IP Address

            #=============================================#
            # Skip management and backend networks
            #=============================================#
            if ( $Null -like $PSitem.defaultipgateway ) {

                $SkippedIPs += $PSitem.ipaddress + ','
                $NetworkFailure = "Skip"   # Skip this Adapter
            }
            else {
                # This adapter has a DFGW, continue working on it
                # IP Exists and has a Default Gateway
                Write-Results -color "Green"  -Header "PASS - " -text "IP Address Check: $($($PSitem.IPaddress)) `n`n"

                #===========================
                # Valid IP, Default Gateway exists. Continue testing this adapter.
                #===========================

                #Get the first two octet of the IP address to compare to known self assigned addresses
                $IPSubScript = $(
                    $($PSitem.ipaddress).Split(".") |
                    Select-Object -First 2
                ) -join "."
                # Get first 3 octet of the IP address
                $IPSubScript3 = $(
                    $($PSitem.ipaddress).Split(".") |
                    Select-Object -First 3
                ) -join "."


                #=============================================#
                # If DHCP Enabled. Test DHCP
                #=============================================#
                if ($PSitem.dhcpenabled -like $True) {
                    $ThisIP = $PSitem.IPAddress
                    # Renew DHCP lease to see if there are DHCP issues.
                    $ThisAdapterToRenew = Get-WmiObject -Class Win32_NetworkAdapterConfiguration |
                    Where-Object { $PSitem.IPAddress -like $ThisIP }
                    $ThisAdapterToRenew.ReleaseDHCPLease() | Out-Null
                    $ThisAdapterToRenew.RenewDHCPLease() | Out-Null


                    if ($IPSubScript.tostring() -notin $SelfAssignedRange -and
                        $PSitem.subnetmask.tostring() -notlike "255.255.0.0"
                    ) {
                        write-results -color "Green" -header "PASS " -text "- DHCP Check: Received IP address via DHCP upon renewal.`n`n"
                    }
                    else {
                        $Text = "- DHCP Check: IP Address on $MACAddress is Self Assigned. `n"
                        $Text += "This likley indicates an incorrect VLAN on the switch port (this machine only): "
                        $Text += "Check to see if another wall jack has a correctly tagged VLAN. Note: "
                        $Text += "Some buildings have jack numbers labled with a V and a D; V stands for Voice and "
                        $Text += "cannot be used for computers, while D stands for Data and can be used for computers. `n"
                        $Text += "If no other wall jacks are available that are tagged correctly, then forward the "
                        $Text += "Building, Room, and Jack Number in question to the networking team to have them tagged.`n"
                        $Text += "Alternativly, there could also be a DHCP Server failure: "
                        $Text += "Run this tool on multiple machines to check for a DHCP server issue.`n`n"
                        Write-Results -color "red"  -header "FAILURE " -text $Text

                        $NetworkFailure = $True

                    }
                } # End If DHCP enabled, check for self assigned IP
                else {
                    # Static IP
                    $Text = "IP Address is statically assigned. Double check Static IP settings to ensure they are correct. `n"
                    $Text += "If this is a general workstation, consider using a DHCP reservation instead, "
                    $Text += "or remove the static IP if it is not required. Talk with Networking for more info. `n`n"
                    write-results -color "Purple" -bold -header  "Skipping DHCP Renew: " -text $Text
                } # End DHCP checks


                #==================================================================================================#
                # Check for non routing and other network oddities.
                #==================================================================================================#

                if ($PSitem.dnsdomain -like "mysvc.skagit.edu") {
                    $Text = "This adapter is reporting a student subnet with a DNS domain name of MySVC.Skagit.Edu. `n"
                    $Text += "Access to Employee Skagit network resources, such as secure92, may be impacted. `n"
                    $Text += "If this machine is not a student/lab machine, send the building, room, "
                    $Text += "and jack number to networking to change to the employee network. `n`n"
                    write-results -color "RED" -header "WARNING: " -text $Text
                }

                #=============================================#
                # check for erroneous wireless networks
                #=============================================#
                if ($SSID) {
                    if ($SSID -in "Skagit", "Disconnected") {
                        write-results -color "Purple" -bold -header "WiFi adapter wireless network: " -text "$SSID `n`n"
                    }
                    else {
                        $Text = "Wi-Fi adapter connected to the $SSID wireless network.`n"
                        $Text += "Access to Skagit network resources may be impacted: "
                        $Text += "Connect to the Skagit wirless network for access to all resources. `n`n"
                        write-results -color "RED" -header "WARNING: " -text $Text
                    }
                }

                #=============================================#
                # check for anyconnect connection.
                #=============================================#
                $AnyconnectConnection = $False
                $Anyconnect = $NetAdapters | Where-Object { $PSitem.description -like "*anyconnect*" }
                if ( $Null -like $Anyconnect.ipaddress ) {
                    'anyconnect is not connected. process as usual'
                }
                else {
                    # AnyConnect is connected
                    $AnyconnectConnection = $True
                    if ( $PSitem.description -NOTlike "*AnyConnect" ) {
                        # This adapter is not anyconnect and will fail it's Default gateway ping since anyconnect is connected.
                        Write-Results -color "Purple" -Bold -header  "AnyConnect VPN Connected: " -text "Skipping this adapter`n`n"
                        $NetworkFailure -like $True
                    }
                }

                #=============================================#
                # Check for Printer subnet IP address
                #=============================================#
                if ($NetworkFailure -like $False) {

                    # Check for printer subnet
                    if ($IPSubScript3.tostring() -like "10.209.209" ) {
                        $Text = "IP Address on $MACAddress is on the 10.209.209 printer subnet. Network will be unavilable.`n"
                        $Text += "Check that the computer network cable is plugged into the right port. If it is, configure the network switch port for the correct VLAN. `n`n"
                        Write-Results -color "red"  -header  "FAILURE: " -text $Text

                        $NetworkFailure = $True
                    }
                } # End check for printer subnet IP address


                #=============================================#
                # Check for nursing SIM LAB DMZ IP address
                #=============================================#
                if ($NetworkFailure -like $False) {

                    # Check for nursing simlab dmz subnet
                    if ($IPSubScript3.tostring() -like "10.209.85" ) {
                        $Text = "IP Address on $MACAddress is on the 10.209.82 Nursing SIM Lab DMZ network. `n"
                        $Text += "Some network functionality will be unavailable. `n`n"
                        Write-Results -color "red"  -header  "WARNING: " -text $Text

                    }
                } # End check for SIM Lab subnet IP address

            }  # End if not management check

        } # IP and DHCP checks.




        #=============================================================================#
        # Routing checks
        #=============================================================================#
        if ($NetworkFailure -like $False) {
            $DFGW = $PSitem.defaultIPgateway[0]
            #  $DFGW = $NetAdapters[2].defaultIPgateway[0]
            #  $DFGW -is [array]



            Try {
                $Ping = Test-PSOnePing -computername $DFGW -Timeout 2000 -ErrorAction stop
                if ($Ping.status -like "Success") {
                    write-results -color "green" -header  "PASS " -text "- Ping to default gateway: $($DFGW).`n`n"
                }
                else { throw }
            }
            Catch {
                $Text = "- Ping to default gateway: $DFGW. `n"
                $Text += "Check other machines for a similar failure to indicate a possible local area network outage.`n`n"
                write-results -color "red" -header  "FAILURE " -text $Text
                $NetworkFailure = $True
            }
        }




        #=============================================================================#
        # DNS Checking
        #=============================================================================#
        if ($NetworkFailure -like $False) {
            # No network failure yet. Continue testing


            $SVCNetwork = "Unknown"

            if ($Null -like $PSitem.DNSServerSearchOrder -or $PSitem.DNSServerSearchOrder -eq 0) {
                $Text = "- DNS Server: No DNS Servers on this network adapter. `n"
                $Text += "Check Static IP settings or DHCP Scope Options. `n`n"
                Write-Results -color "Red" -header  "FAILURE " -text $Text
                $NetworkFailure = "DNS"
            }
            else {
                $DNSFailureCount = 0
                $PingFailureCount = 0
                Write-Results -color "black" -header  "DNS Server Checks:" -bold -text " "
                foreach ( $DNSServer in $PSitem.DNSServerSearchOrder ) {

                    try {
                        $Resolution = Resolve-DnsName $DNSServer -Server $DNSServer -ErrorAction stop
                        $SVCNetwork = if ($Resolution.NameHost -like "*Skagit.edu") { $True } else { $False }
                        Write-Results -text $([system.environment]::NewLine)
                        Write-Results -color "Green" -header 'PASS: ' -text " $DNSServer`: $($Resolution.NameHost)   "

                        $DNSMsg += "PASS: DNS" # Why is this here? What was I going to do with it? I think I can delete it now.
                    }
                    catch {
                        Write-Results -text $([system.environment]::NewLine)
                        Write-Results -color "red" -header '[ FAILURE: ' -text " $DNSServer | "

                        $DNSFailureCount ++
                        try {
                            $ping = Test-PSOnePing -ComputerName $DNSServer -Timeout 3000 -ErrorAction stop
                            if ($Ping.status -NOTlike "Success") { $PingFailureCount ++ ; throw }
                            Write-Results -color "Green" -Header "PASS " -text "- Ping Test: The server is online but having a DNS outage. ]   "
                        }
                        catch {
                            Write-Results -color "red" -Header "FAILURE " -text "- Ping Test: The server is offline, preventing it from serving DNS lookup. ]   "
                        }
                    } # end try catch

                } # End for each dns server

                # new line after DNS testing
                write-results -color 'black' -text " `n`n" # close the paragraph for the DNS server tests.

                # Check to see if all DNS failed. # -and ( $PSitem.DNSServerSearchOrder.count -gt 1 )
                if ( ( $DNSFailureCount -eq $PSitem.DNSServerSearchOrder.count )  ) {
                    Write-Results -color "Red" -Header "FAILURE " -text "- Lookup to all DNS servers failed: "
                    if ($PSitem.DHCPenabled -like $False) {
                        Write-Results -color "purple" -bold -Header "DNS servers designated via Static IP: " -text "Confirm Static IP settings are correct. "
                    }
                    switch ($SVCNetwork) {
                        $True { Write-Results -color "purple" -bold -Header "Skipping SVC Resource tests: " -text "They will fail due to the DNS outage. `n`n" }
                        $False { Write-Results -color "purple"  -bold -Header "Off SVC Network: " -text "Contact your internet service provider. `n`n" }
                        "Unknown" { Write-Results -color "purple" -bold -Header "Unable to detect SVC Network due to DNS failure: " -text "If on SVC network, contact networking. If off SVC network, contact your internet service provider. `n`n" }
                    }


                    $NetworkFailure = "DNS"

                    if ($PingFailureCount -eq $PSitem.DNSServerSearchOrder.count ) {
                        $Text = "- Ping to all DNS Servers failed: `n"
                        $Text += "If there are multiple machines reporting this error, then there may be a server level outage.`n`n"
                        write-results -color "red" -Header "FAILURE " -text $Text
                    }
                    else {
                        $Text = "- DNS servers are still responding to ping. `n"
                        $Text += "Network issues may be related only to the DNS service.`n`n"
                        write-results -color "purple" -bold -Header "NOTE " -text $Text
                    }

                } # end if all DNS servers failed their DNS lookup

            } # End DNS check

        } # End Netowrk failure check b4 DNS check


        #==============================================#
        # Check file server connection
        #==============================================#
        if ( $NetworkFailure -like $False ) {

            if ($SVCNetwork -like $False) {
                $Text = "Skipping Network file access checks. `n"
                $Text += "[Logon server ping failed, AnyConnect VPN not connected, "
                $Text += "non Skagit DNS domain name detected, or non 10.(32/209).0.0 address range.]`n"
                $Text += "If actually on the SVC network, contact networking. `n`n"
                Write-results -color "Purple" -bold -header "Off SVC Networks: " -text $Text
            }
            else {

                if ($env:USERDNSDOMAIN -like "MV.skagit.edu" -or
                    $env:USERDNSDOMAIN -like "Skagit.edu") {
                    Write-Results -color "black" -Bold -Header "SVC Network File Access Checks:" -text " "

                    $Text = "Name, Path`n"
                    $Text += "Root Datastore DFS Share, \\mv.skagit.edu\datastor`n"
                    $Text += "Departments U: Drive, \\mv.skagit.edu\datastor\depts`n"
                    $Text += "Employee redirected my documents, \\mv.skagit.edu\datastor\empdoc"
                    $Sites = $Text | ConvertFrom-Csv

                    $Sites | ForEach-Object {
                        if ( Get-ChildItem -Path $psitem.path ) {
                            write-results -color "green" -header "`nPASS: " -text "$($psitem.Name)"
                        }
                        else {
                            write-results -color "red" -header "`nFAILURE: " -text "$($psitem.Name)"
                        }
                    } # end % file access check
                    write-results -text "`n`n"
                }
                else {
                    write-results -color "Purple" -bold -header "Skipping SVC Network File Access Check: " -text "User is not in a domain with access. To test this, log into the computer, or run the ITComputerInfo.exe applet as an MV/Employee account..`n`n"

                } # end if employee check for file access


            } # End If On campus check


        } # End file checks



        #==============================================#
        # Internet check. start with IP.
        #==============================================#
        if ( $NetworkFailure -like $False -or $NetworkFailure -like "DNS") {

            $Text = "Name, URI`n"
            $Text += "CloudFlare DNS, https://1.1.1.1`n"
            $Text += "CloudFlare DNS, https://1.0.0.1`n"
            $Text += "OpenDNS, https://208.67.222.222`n"
            $Text += "OpenDNS, https://208.67.220.220`n"
            $Text += "Quad9 DNS, https://9.9.9.9`n"
            $Text += "Quad9 DNS, https://9.9.9.11`n"
            $Sites = $Text | ConvertFrom-Csv

            $StatusCode = $Null

            ForEach ($Site in $Sites) {

                If ( $Null -like $StatusCode ) {
                    $Site
                    try {
                        $Response = Invoke-WebRequest -Uri $Site.URI -UseBasicParsing
                        # This will only execute if the Invoke-WebRequest is successful
                        $StatusCode = $Response.StatusCode
                    }
                    catch {
                        $StatusCode = $_.Exception.Response.StatusCode.value__
                    }
                    $SitePass = $Site
                } # end  null check
            } # End For Each IP to test

            Write-Results -color 'black' -bold -Header 'Internet Connection Checks: ' -text ' '
            if ($Null -like $StatusCode) {
                $Text = "All internet checks failed. `n"
                $Text += "Since internet was not possible via IP, which does not rely on DNS, `n"
                $Text += "then this may be an Internet Service Provider level network outage.`n`n"
                write-results -color "red" -Header "FAILURE: " -text $Text
                $NetworkFailure = "Internet"
            }
            else {

                Write-Results -color "Green" -Header "`nPASS: " -text "$($sitepass.name) {$($Sitepass.uri)} response: {$StatusCode}"
                #else { Write-Results -color "black" -text "`n" }
            }

        } # end internet via IP check

        # Is this IF correct?
        if ( $NetworkFailure -like $False -or $NetworkFailure -like "DNS") {

            # just a popup to show something to the user so they know the test is not frozen.
            <#
                $shell.popup( "This popup lets you see some results. YAY!",
                    1, "Network Testing:", $ShowOnTop + $Icon.Exclamation + $Buttons.OK
                )
                   #>
            switch ($NetworkFailure) {
                "DNS" { $webFailMsg = "Failure - [DNS]" }
                "Internet" { $webFailMsg = "Failure - [Internet]" }
                $False { $webFailMsg = "Failure - [Site]" } # end false
            } # end switch for web requests



            $Text = "Name,              URI`n"
            $Text += "SVC Homepage,     www.skagit.edu`n"
            $Text += "ctcLink Login,    gateway.ctclink.us`n"
            $Text += "Canvas,           skagit.instructure.com`n"
            $Text += "WA K20 Network,   stats.wa-k20.net`n"
            $Text += "O365 Email,       outlook.office365.com`n"
            $Text += "Office 365,       portal.office.com`n"
            $Sites = $Text | ConvertFrom-Csv

            ForEach ($Site in $Sites) {
                $StatusCode = $Null
                $Site
                try {
                    $Response = Invoke-WebRequest -Uri $Site.URI -UseBasicParsing
                    # This will only execute if the Invoke-WebRequest is successful
                    $StatusCode = $Response.StatusCode
                    Write-Results -color 'green' -header  "`nPASS: " -text "$($site.name) {$($Site.uri)} {$StatusCode}"
                }
                catch {
                    $StatusCode = $_.Exception.Response.StatusCode.value__
                    Write-Results -color 'red' -header "`n$webFailMsg`:" -text "$($site.name) {$($Site.uri)} {$StatusCode}"

                }
            } # End For Each IP to test

            write-results -color 'black' -text "`n`n"

            if ($NetworkFailure -like "DNS") {
                $Text = "This tells us that we have internet connectivity despite the DNS outage. The outage is only DNS related.`n`n"
                Write-Results -color "Black" -Header $Text
            }

        } # end test for internet

        if ($NetworkFailure -NotLike "Skip") {
            Write-Results -bold -header  "Done Testing Adapter with IP $($($PSitem.IPaddress)) `n`n"
        }

    } # VLans on this mac address for each

} # For Each MAC Address

#=================================
# Wrap up
#=================================
If ($SkippedIPs.count -gt 0) {
    $Text = "$SkippedIPs"
    $Text += " If you are having issues with these subnets, please contact the Networking team.`n`n"
    Write-Results -color "Purple" -bold -header  "Skipped adapters that are missing default gateways: `n" -text $Text
}

$Text = "`n`nHelp Desk Technician, Please review results and contact networking if appropriate.`n`n"
$Text += "If you think there is a switch/server network level failure, run the tool on multiple machines in two or more buildings each.`n`n"
Write-Results -Bold -header "Done Testing Network:`nPlease provide the results to the Help Desk for review: " -text $Text

# Put test results into a variable so we can copy it later
[System.Windows.Forms.RichTextBoxStreamType]::PlainText
$NetworkTestResultsRange = New-Object System.Windows.Documents.TextRange(
    $WPFtxbResults.Document.ContentStart, $WPFtxbResults.Document.ContentEnd )
$script:NetworkTestResults = $NetworkTestResultsRange.text.Clone()

# Reset form to show that testing is done
#$WPFbtnTestNetwork.Foreground = "black"
#$WPFbtnTestNetwork.Background = "#FF9ADE90"
$WPFbackNetwork.background = "#FF9ADE90"
$WPFbtnTestNetwork.Content = "Test Complete"
$WPFWindowITComputerInfo.title = "SVC IT Computer Info"
$WPFbtnCopy.Background = "#FFDDDDDD"
$WPFbtnCopy.content = "Copy Info to Clipboard"

$Msg = "Testing Complete:`n"
$Msg += "Please have the Help Desk review results. "
$shell.popup( $Msg, 5, "Network Testing:", $ShowOnTop + $Icon.Exclamation + $Buttons.OK )









<#

To Do:

can we break it with a static IP?

move things back into functions that are only needed by the function

Other testing/control for misses on dns/web/file checks????? How to test that failing?

Ping state board?



DNS check using actual DNS servers?

VPN anyconnect test?
    $env:logonserver: there. tells us nothing
    WMI netdomain:
    Can we somehow detect SBL?
    What changes when off and then vpn?
    Not being detected because it does not have a DFG

what works on student subnet network test

test ssid, skagit and other, in network test

do DCs generate when DNS is broken? off line?

mysvc.sk.edu in DHCP



dhcp error clarification


Get log on server IP and name:
Ping it to see if on network.
NS look up it to see if local DNS is working
NSlookup online to see if web DNS is working (if local/off?)
Report DNS working depending on results of local/web
continue testing other things depending on results of based on DNS results


ping to state board and google or M$oft


Jim's subnets:
Printer: 10.209.249

Jim's switch 10.32.238.1

Can this subnet traverse the FW to the other campus? can NSlookup but cannot Ping means you cannot traverse FW
can traverse the state board?


IP Address of DFS servers for testing? why bother? who is going to use the network resources if DNS is down?


The first msgbox should change all the buttons and loading info for the testing notifications.






routing even if DNS failure






Basics of network troublshooting

Valid IP Address

DHCP: Renew sets Valid IP Address

Routing:
    Ping Default Gateway
    Ping/WebRequest Internet IP Address
    WIC/MV?
    State Board?

DNS:
   Lookup each DNS Server
   Ping down DNS Servers




Add:
MV/WIC Firewall check? can we ping?

MV Routing:
K20 Router to FW ping 192.64.1.177
FW Inside to core  192.64.1.185
Core 192.64.1.187

WIC Routing:
K20 Router to FW 216.186.40.225
FW Inside to core 10.209.0.2
Core to FW 10.209.0.1

Internet:
1.1.1.1 and 8.8.8.8


MV FW   |   K20 Router  |   ISP





(nltest /server:$env:logonserver /dsgetsite)[0]





#>


