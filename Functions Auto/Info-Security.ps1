
#===========================================================================
# Security
#===========================================================================
function Get-SVCSecurityInfo {



    #======================================
    # Defender periodic scanning
    #======================================
    try {
        $AV = Get-MpComputerStatus -ErrorAction stop
    }
    catch {
        $AV = [pscustomobject]@{ AntivirusEnabled = $False }
    }


    If ( $False -like $AV.AntivirusEnabled) {
        # This field is named Enabled, but the label is Status
        $AVEnabled = "Dissabled"
        $AVUpdated = $Null
        $AVVersion = $Null

        $Text = "Windows Defender Antivirus is dissabled."
        $( If (Test-Path ( "C:\Program Files (x86)\Symantec\Symantec Endpoint Protection") ) {
                $Text += "Please uninstall Symantec Endpoint Protection."
            }
        )
        $Text += "`n`n"
        Write-Results -color "Red" -Bold -header "CRITICAL: " -text $Text
        $WPFbacksecurity.background = $FormRed
    }
    else {
        # This field is named Enabled, but the label is Status
        $AVEnabled = "Enabled"
        $AVUpdated = $AV.AntivirusSignatureLastUpdated
        if ( $AV.AntivirusSignatureLastUpdated -lt (Get-Date).AddDays('-5')) {
            # Yes. 2 days is extreem. But this is for Security. Live with it.
            Write-Results -color "Red" -Bold -header "CRITICAL: " -text "Antivirus DATs have not updated recently. They should update daily. Please see this KB article for steps to update them: https://skagit.teamdynamix.com/TDClient/2053/Portal/KB/ArticleDet?ID=138048 `n`n"
            $WPFbacksecurity.background = $FormRed
        }
        $AVVersion = $AV.AntivirusSignatureVersion
    }

    #Output defender info
    [PSCustomObject]@{
        "Header1" = "Microsoft Defender Periodic Scanning"
        "Status"  = "$AVEnabled"
        "Updated" = "$AVUpdated"
        "Version" = "$AVVersion"
    }



    #======================================
    # AV WMI call. Gets all installed AV.
    #======================================
    $AVWMIParams = @{
        Namespace   = "root/SecurityCenter2"
        ClassName   = "Antivirusproduct"
        ErrorAction = "Stop"
    }
    $AV = Get-WmiObject @AVWMIParams

    [int]$Header = 2

    Function ConvertTo-Hex {
        # Used for AV info
        Param([int]$Number)
        '0x{0:x}' -f $Number
    }

    foreach ($item in $AV) {
        if ($Item.displayName -like "Symantec Endpoint Protection") {
            if (Test-Path "C:\Program Files (x86)\Symantec\Symantec Endpoint Protection") {
                # SEP is installed. Process the item.
            }
            else {
                continue # SEP is not installed. Skip it...
            }
        }

        $hx = ConvertTo-Hex $item.ProductState
        $mid = $hx.Substring(3, 2)
        if ($mid -match "00 | 01") {
            $Status = "Dissabled"
            $AVDissabled = $True # for a write result later
        }
        else {
            $Status = "Enabled"
        }
        $end = $hx.Substring(5)
        if ($end -eq "00") {
            $UpToDate = $True
        }
        else {
            $UpToDate = $False
        }

        # set the AV the AV info to output
        $Header ++
        $Output = [PSCustomObject]@{
            "header$Header" = $Item.displayName
            "Status"        = "$Status"
            "Up To Date"    = "$UpToDate"
        }

        if ( $item.displayname -like "*Sentinel*") {
            $SentinelVersion = $Item.pathToSignedProductExe.Split(" \")[6] | Where-Object { $PSitem -match '\d' }
            $Output | Add-Member -MemberType noteproperty -Name "Version" -Value $SentinelVersion

        }
        # Output this AV info
        $Output

    } # AV Item foreach

    if ( $AVDissabled ) {
        Write-Results -bold -header "CRITICAL: " -color 'red' -text  "Antivirus dissabled."
        $WPFbacksecurity.background = $FormRed

    }






    #======================================
    # Firewall status
    #======================================
    $Header ++
    $Output = [pscustomobject] @{"Header$Header" = "Windows Firewall Status" }


    Get-NetFirewallProfile |
    ForEach-Object {

        # Set a flag if any firewall profile is dissabled. Later we will write a message from this flag.
        if ( $PSitem.enabled -like $False ) { $FWDissabled = $True }

        $FWStatus = if ($PSitem.Enabled -like $True ) { "Enabled" }else { "Disabled" }

        $Output | Add-Member -MemberType noteproperty -Name $PSItem.Profile -Value $FWStatus

    }

    #Output Firewall Status to info text box
    $Output

    if ( $FWDissabled -like $True ) {
        Write-Results -color "Red" -Header "WARNING: " -text "Windows Firewall Dissabled. `n`n"
        $WPFbacksecurity.background = $FormYellow

    }






    #============================================
    # Get Windows update/hotfixes
    #============================================
    $HotFixes = $(
        Get-HotFix | Sort-Object installedon -Descending | Select-Object hotfixid, description,
        @{Name = "InstalledOn"; Expression = { $PSitem.installedon.toshortdatestring() } }
    )


    $Header ++
    $Output = [pscustomobject] @{
        "Header$Header"         = "Windows Updates"
        "Header100000000000000" = "KB Number   Installed    Type"
    }


    Foreach ($HotFix in $HotFixes) {
        $InfoText += "`n" + $HotFix.hotfixID + "   " + $Hotfix.Installedon + "   "

        Switch ($Hotfix.InstalledOn.Length) {
            8 { $Spaces = "     " }
            9 { $Spaces = "    " }
            10 { $Spaces = "   " }
        }
        $Text = "$($HotFix.hotfixID)   $($Hotfix.Installedon)$Spaces$($Hotfix.Description)"
        $Header ++

        $Output | Add-Member -MemberType noteproperty -Name "Header$Header" -Value  $Text

    }

    # Output updates to text box
    $Output

} # AV Info



