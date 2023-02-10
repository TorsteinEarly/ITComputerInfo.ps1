

#===========================================================================
# Computer

# Lots of WMI calls and warnings on this one.
# We will process each call and warning before compiling the object
# This is mostly in order. Some checks will refference earlier calls.
#===========================================================================

Function Get-SVCComputerInfo {


    $Bios = Get-WmiObject win32_systemenclosure




    #================================
    # Domain Checks
    #================================

    $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem

    if ($Computersystem.domain -like "WORKGROUP") {
        $WPFbtnFixTrust.Content = "Trust: Workgroup"
        # Do not process any domain checks... Because, duh
    }
    else {
        # run the domain checks...


        if ( Test-ComputerSecureChannel ) {

            # Domain Trust Relationship passed: get this computers OU
            try {
                $ADSISearcher = New-Object System.DirectoryServices.DirectorySearcher;
                $ADSISearcher.Filter = '(&(name=' + $env:computername + ')(objectClass=computer))';
                $ADSISearcher.SearchScope = 'Subtree';
                $Computer = $ADSISearcher.FindAll();

                # Make an outputable OU for the tool:
                $OU = (
                    $( $Computer.path -replace "LDAP://CN=$($Env:Computername),|OU=|DC=|skagit|edu", ''
                    ).trimend(',,'
                    ).split(',')
                )
                [array]::reverse($OU) | Out-Null

                $OUHeader = "AD OU         : "
                $OULength = 0

                $OU | ForEach-Object {

                    if ($($OULength + $PSitem.length + 1) -gt 29) {
                        $OUHeader += "`nAD OU cont    : $PSitem\"
                        $OULength = $PSitem.length + 1
                    }
                    else {
                        $OUHeader += "$PSitem\"
                        $OULength += $PSitem.length + 1
                    }
                } # end OU Header foreach

                $OUHeader = $OUHeader.trimend('\')



                # Get OU parent and try to find what campus/building the OU/computer is in. Later we will check these.
                $OUDN = (
                    $( $Computer.path -replace "LDAP://CN=$($Env:Computername),", ''
                    )
                )
                $ADSISearcher.PropertiesToLoad.Add('*') | Out-Null
                $ADSISearcher.Filter = '(&(distinguishedname=' + $OUDN + ')(objectClass=Organizationalunit))';
                $ADSISearcher.SearchScope = 'Subtree';
                $OU = $ADSISearcher.FindAll()

                $OUParent = $OU.Properties.ou
                $OUDescription = $OU.Properties.description
            }
            catch {
                $OUHeader = "AD OU [ERROR] : [DC Unreachable]"
            }
            finally {
                $ADSISearcher.dispose()
            }
        }
        else {
            # Domain Trust broken... Or is it?

            $DNSServers = (
                Get-DnsClientServerAddress -AddressFamily IPv4 |
                Select-Object -First 1 -ExpandProperty serveraddresses |
                ForEach-Object {
                    Resolve-DnsName -Name $PSitem -ErrorAction SilentlyContinue |
                    Select-Object -ExpandProperty namehost
                }
            )



            If ($DNSServers -match "Skagit.edu") {

                $OUHeader = "AD OU [ERROR] : [AD Trust Broken]"

                $Text = $(
                    "Trust relationship with Active Directory is broken. `n`n"
                    "Cannot check Active Directory for a computer account.`n`n"
                    "Cannot check Active Directory OU path.`n`n"
                    "Click the Fix Trust Relationship button on the network tab.`n`n"
                )
                write-results -bold -color 'red' -header "CRITICAL: " -Text $Text

            }
            else {

                $OUHeader = "AD OU [ERROR] : [Off SVC Net]"


            }
        } # End if /else trust test


    } # End if workgroup or domain


    #====================================
    # check for proper computer name
    #====================================
    $CompNameSite = ( $env:computername -split '-' )[0]

    # Add the dash back in to weed out any potential dell serial numbers that look like a site code...
    if ($($CompNameSite + "-") -in "MV-", "WC-", "SJ-", "MT-", "HS-") {
        # Proper name
        $Text = "Computer name matches Campus-BuildingRoom-Asset like MV-F206-04589 for a "
        $Text += "computer on the MV campus in Ford Hall room 206. `n`n"
        $Text += "Please confirm that the name is correct for the computer location. `n`n"
        Write-Results -color "Purple" -bold -Header "NOTE: " -Text $Text

        $NameToOUTest = "Site"
        # insert OU to comsputername comparison here... Need to build a hash table. Oii...
        # $OUParent

    }
    else {
        If ($env:COMPUTERNAME -like $Bios.serialnumber ) {
            # Proper loaner  name
            $Text = "Computer name matches Serial; This is typical of Loaner Laptops. `n`n"
            $Text += "If this computer is not a loaner (IE, it is assigned to a spesific location/employee) "
            $Text += "then contact the Help Desk to have it renamed. `n`n"
            Write-Results -color "purple" -bold  -Header "NOTE: " -Text $Text
            $NameToOUTest = "Loaner"
        }
        else {
            # Not a proper name
            $Text = "Computer name does not match an IT Help Desk defined naming convention. "
            $Text += "Rename according to IT Conventions detailed at "
            $Text += "https://skagit.teamdynamix.com/TDClient/2053/Portal/KB/ArticleDet?ID=132538 `n`n"
            Write-Results -color  "purple" -bold  -header "NOTE: " -Text $Text
            $NameToOUTest = "Nope"
        }
    } # Done testing computername


    #====================================
    # Name to OU check
    #====================================
    if ($OUHeader -like "*error*" ) {
        $NameToOUTest = "Nope"
    }

    if ($Computersystem.domain -like "Workgroup") {
        $NameToOUTest = "WorkGroup"
    }

    switch ($NameToOUTest) {
        "WorkGroup" {  }
        "Loaner" {
            if ( $OUParent -in "_RA-laptops", "Loaner Laptops", "000-MobileLapTop" ) {
                # Good. It is correct.
            }
            else {
                $Text = "Machine named like Serial Number for a loaner laptop, but is not in a loaner laptop OU: `n`n"
                $Text += "MV Domain Loaner OU: _RA-laptops\machine\mv`n"
                $Text += "MySVC Domain Loaner OU: Loaner Laptops\machine\MySVC`n`n"
                $Text += "Help Desk: Double check that the machine is in the correct OU. "
                $Text += "See computer naming convention KB for more info.`n`n"
                Write-Results -color  "red" -bold  -header "WARNING: " -Text $Text
            }
        } # End Loaner
        "Site" {

            $CompNameBuildingRoom = ( $env:computername -split '-' )[1]

            switch ( $CompNameSite ) {
                # These sites do not have sub OUs. I just listed all their descriptions as their site code.
                "MT" { if ( $OUDescription -NOTlike "MT" ) { $OUError = $True } }
                "SJ" { if (  $OUDescription -NOTlike "SJ" ) { $OUError = $True } }
                "SW" { if (  $OUDescription -NOTlike "SW") { $OUError = $True } }
                # Head Start should be in the head start folder.
                "SIHS" { if ( $OUParent -NOTlike "SIHS" ) { $OUError = $True } }
                default {
                    # should be MV or WC

                    # Yes! Really -Match here rather than Like.
                    # For Instance, matching T to T56-60 as in the case of automotive [sigh]
                    # And and matching L101A to L. This right here is the magic.
                    # And, yeah, in both orders just in case there are funky extras... Oii.
                    # I hate everything about this. But it works...
                    if ( $CompNameBuildingRoom -match $OUParent -or
                        $CompNameBuildingRoom -match $OUDescription -or
                        $OUParent -match $CompNameBuildingRoom -or
                        $OUDescription -match $CompNameBuildingRoom -or
                        $CompNameSite -Like $OUDescription
                    ) {
                        # match on any of these means that we have a good name.
                    }
                    else {
                        # All matches failed. Must be a bad name.
                        $OUError = $True
                    }

                } # End MV or WC

            } # End CompNameSite switch

        } # End Site check in switch NameToOUTest
        "Nope" {

            $Text = "Unable to check machine name to see if it is in the correct OU in AD. "
            $Text += "Double check that the machine is in the correct OU. "
            $Text += "See computer naming convention KB for more info.`n`n"
            Write-Results -color  "purple" -bold  -header "NOTE: " -Text $Text
        }
    }# End NameToOUTest Switch

    if ($OUError -like $True ) {
        $Text = "Name checks against AD OU and OU Description do not match - "
        $Text += "It appears that the machine is in the wrong OU, or the OU is missnamed, "
        $Text += "or the OU description is set incorrectly.`n`n"
        $Text += "OU Description: [ $OUDescription ]`n"
        $Text += "OU Description should be: "
        $Text += "Site Initial for smaller sites: MT/SJ/SIHS/SW `n"
        $Text += "Building Initial(s), to match the building initial in the Computer Name, "
        $Text += "for MV Domain OUs at MV/WC: A/C/CA/T/ECB... or "
        $Text += "BuildingInitialRoom Code for Classrooms/Podium Computers for classrooms at MV/WC: F104, A137. `n`n"
        $Text += "Help Desk: Double check that the machine is in the correct OU. "
        $Text += "If it is, please have Torstein review the OU name and description "
        $Text += "in case this tool needs to be corrected... (Note: Never rename OUs in AD!)`n`n"
        $Text += "See computer naming convention https://skagit.teamdynamix.com/TDClient/2053/Portal/KB/ArticleDet?ID=132538  for more info.`n`n"
        Write-Results -color  "red"  -header "WARNING: " -Text $Text

    }



    #================================
    # Bios checks
    #================================

    if ( $Null -like $Bios.SMBIOSAssetTag) {
        Write-Results -color "purple" -bold  -header "NOTE: " -text "Missing IT/SVC State Tag in BIOS Asset Tag field.`n`n"
    }



    #================================
    # Last boot check
    #================================

    $OperatingSystem = Get-CimInstance Win32_OperatingSystem

    $DaysSinceStartup = $(
        (Get-Date) - $OperatingSystem.LastBootUpTime |
        Select-Object -ExpandProperty days
    )

    If ($DaysSinceStartup -ge 5) {
        $Text = "Computer has not been restarted in more than 5 days, which can cause several issues."
        $Text += "Please restart regularly.`n`n"
        Write-Results -color "red" -header "WARNING: " -Text $Text
        $WPFbackbasics.background = $FormYellow
    }


    #================================
    # OS version checks
    #================================

    $OSVersion = $( Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" )
    # Check for out of date versions of Windows.
    # https://docs.microsoft.com/en-us/lifecycle/products/windows-10-enterprise-and-education
    if ( $Null -like $OSVersion.DisplayVersion) {} else {
        $VersionYear = $OSVersion.DisplayVersion.Substring(0, 2)
    }

    $CurrentYear = Get-Date -Format yy
    if (  $VersionYear -gt ($CurrentYear - 2)  ) {
        # Windows supported...
        # Ok, I know, it's not so straight forward as a two year suppor cycle. But lets roll with it.
    }
    else {
        $Text = "Windows OS Version is Unsupported! `n"
        $Text += "Please redeploy machine via ConfigMgr, or see this KB article for an in place upgrade: "
        $Text += "https://skagit.teamdynamix.com/TDClient/2053/Portal/KB/ArticleDet?ID=138400 `n`n"
        Write-Results -color "Red"  -Bold -header "CRITICAL: " -text  $Text
        $WPFbackbasics.background = $FormRed

    }


    [pscustomobject]@{
        "Name (FQDN)"   = "$($env:COMPUTERNAME + "." + $ComputerSystem.domain)"
        "Header100"     = $OUHeader
        "Current User"  = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
        "BlankLine1"    = $Null
        "Header1"       = "$($ComputerSystem.Manufacturer) $($Computersystem.Model)"
        "Serial Number" = "$($Bios.serialnumber)"
        "Asset Tag"     = "$( $Bios.SMBIOSAssetTag )"
        "BlankLine2"    = $Null
        "Header2"       = "$($OSVersion.productname)"
        "CompEditionID" = "$($OSVersion.CompositionEditionID) ; SKU: $($operatingsystem.operatingsystemsku)"
        "OS Version"    = "$($OSVersion.CurrentBuild).$($OSVersion.UBR) $($OSVersion.DisplayVersion)"
        "Install Date"  = $($OperatingSystem.InstallDate).toshortdatestring()
        "Startup"       = $OperatingSystem.LastBootUpTime.toshortdatestring()
    } # End output object

    if ($OSVersion.CompositionEditionID -Notin "Enterprise", 'Education') {
        $Text = "We typically run Enterprise. "
        $Text += "Some OS features may be unavailable and you may be unable to run upgrades via ConfigMgr."
        write-results -header "WARNING" -color 'red' -text $Text
        $WPFtxtComputerInfo.background = $FormYellow
    }


} # end computer info












