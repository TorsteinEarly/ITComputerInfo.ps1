











$SVCInfoVersion = (Get-ChildItem -Name V*).replace(".txt", "")


$inputXML = (Get-Content ".\functions static\formxaml.txt" ).Replace(
    'ToolTip="$SVCInfoVersion', $("ToolTip=`"$SVCInfoVersion")
)



#         $InputXML = Get-Clipboard




$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'

[void][System.Reflection.Assembly]::LoadWithPartialName( 'System.Windows.Forms' )
[void][System.Reflection.Assembly]::LoadWithPartialName( 'presentationframework' )
Add-Type -AssemblyName PresentationFramework, System.Drawing, System.Windows.Forms, WindowsFormsIntegration

[xml]$XAML = $inputXML
#Read XAML


$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try {

    $Form = [Windows.Markup.XamlReader]::Load( $reader )
}
catch {
    Write-Warning "Unable to parse XML, with error: $($Error[0])`n Ensure that there are NO SelectionChanged or TextChanged properties in your textboxes (PowerShell cannot process them)"
    throw
}




#===========================================================================
# Load XAML Objects In PowerShell
#===========================================================================

$xaml.SelectNodes("//*[@Name]") | ForEach-Object {
    ###  "trying to add item $($_.Name)";
    try { Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) -ErrorAction Stop }
    catch { throw }
}

Function Get-FormVariables {
    if ($global:ReadmeDisplay -ne $true) {
        Write-Host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;
        $global:ReadmeDisplay = $true
    }
    Write-Host "Found the following interactable elements from our form" -ForegroundColor Cyan
    Get-Variable WPF*
}




#===========================================================================
# dot source functions
#===========================================================================

(Get-ChildItem .\"functions auto").fullname | ForEach-Object { . $PSitem }



$shell = New-Object -ComObject WScript.Shell
$buttons = @{
    OK               = 0
    OkCancel         = 1
    AbortRetryIgnore = 2
    YesNoCancel      = 3
    YesNo            = 4
    RetryCancel      = 5
}

$icon = @{
    Stop        = 16
    Question    = 32
    Exclamation = 48
    Information = 64
}

$clickedButton = @{
    -1 = 'Timeout'
    1  = 'OK'
    2  = 'Cancel'
    3  = 'Abort'
    4  = 'Retry'
    5  = 'Ignore'
    6  = 'Yes'
    7  = 'No'
}

$ShowOnTop = 4096
# $shell.popup($Text, 0, "Network Testing:", $ShowOnTop + $Icon.Question + $Buttons.YesNo)





# colors used in the form to denote problems
$FormRed = "#FFFF4B4B"
$FormYellow = "#FFFDF9A2"
$FormGreen = "#FF9ADE90"


#===========================================================================
# Tab Control
#===========================================================================

# Scroll to the top of the info text boxes when they are initialy loaded...

$ScrollScript = {
    if (Get-Variable -Name $($this.name + "Loaded") -Scope Script -ErrorAction SilentlyContinue ) {
        $This.ScrollTohome() # Yes... Here too. Sometimes the first will not trigger.
        $This.remove_requestbringintoview($ScrollScript)
        Remove-Variable -Name $($this.name + "Loaded")  -Scope Script
    }
    else {
        New-Variable -Name $($this.name + "Loaded") -Value $True -Scope Script
        $This.ScrollTohome() # First
    }
} # End scroll script

Get-Variable -Name "wpftxt*info" |
ForEach-Object {
    $PSitem.value.add_requestbringintoview( $ScrollScript )
}





#===========================================================================
# Clicks
# Get-FormVariables | Where-Object { $_.name -like "*btn*" } | Select-Object -ExpandProperty name
#===========================================================================
#Text Boxes
$WPFtxtComputerInfo.add_mousedoubleclick({ sysdm.cpl })

# Upper buttons
$WPFbtnKB.Add_Click({ Start-Process microsoft-edge:https://skagit.teamdynamix.com/TDClient/2053/Portal/KB/ })
$WPFbtnHelpDesk.Add_Click({ Start-Process microsoft-edge:https://skagit.teamdynamix.com/TDClient/2053/Portal/Home/?ID=d0d7411d-bbeb-4508-b94d-42f1ec71dfc0 })
$WPFbtnTicket.Add_Click({ Start-Process microsoft-edge:https://skagit.teamdynamix.com/TDClient/2053/Portal/Requests/ServiceCatalog })
$WPFbtnPortal.Add_Click({ Start-Process microsoft-edge:https://skagit.teamdynamix.com/TDNext/ })

# Tab Buttons
$WPFbtnFixTrust.add_click({ . ".\functions static\FixTrustRelationship.ps1" })
$WPFbtntestnetwork.add_click({ . ".\functions static\test-svcnetwork.ps1" })
$wpfbtndiskcleanup.add_click({ . ".\functions static\Invoke-SVCCleanMgr.ps1" } )
$WPFbtnCheckdisk.add_click({ . ".\functions static\Invoke-SVCCheckDisk.ps1" })
$WPFbtnDownloadCleanup.add_click({ . ".\functions static\Clear-SVCDownloads.ps1" })

#Lower Buttons
$wpfbtnHelp.add_click({ . ".\functions static\help.ps1" })
$WPFbtnReload.Add_Click(
    {
        $WPFtxbResults.Document.Blocks.Clear() # clear previous results
        $WPFbtnCopy.Background = "#FFDDDDDD"
        $WPFbtnCopy.content = "Copy Info"
        $WPFbtnTestNetwork.Content = "Run Network Test"


        Get-SVCComputerInfo | Convert-SVCInfoToForm  -Control $WPFtxtComputerInfo

        Get-SVCNetworkInfo | Convert-SVCInfoToForm  -Control $WPFtxtNetworkInfo
        Get-SVCSecurityInfo | Convert-SVCInfoToForm  -Control $WPFtxtSecurityInfo
        Get-SVCMemoryInfo | Convert-SVCInfoToForm  -Control $WPFtxtMemoryInfo
        Get-SVCStorageInfo | Convert-SVCInfoToForm  -Control $WPFtxtStorageInfo

        Get-BSODResults
        invoke-resultscheck

    }
)
$WPFbtnCopy.Add_Click( {
        . ".\functions static\copy.ps1"
        invoke-svccopy
    }
)



#===========================================================================
# Show the form
#===========================================================================



# Initial view to show the user the form is in fact loading.
$Form.add_Loaded({


        $WPFWindowITComputerInfo.Icon = "C:\Program Files\SVC Tools\itcomputerinfo\ITComputerInfo.ico"
        $WPFtxbResults.Document.Blocks.Clear() # Clear "loading" from the results

        Get-SVCComputerInfo | Convert-SVCInfoToForm  -Control $WPFtxtComputerInfo



    }
)
# Get-FormVariables | Where-Object { $_.name -like "*tab*" } | Select-Object -ExpandProperty name

# Update after showing the form.
$Form.add_ContentRendered({



        Get-SVCNetworkInfo | Convert-SVCInfoToForm  -Control $WPFtxtNetworkInfo
        Get-SVCSecurityInfo | Convert-SVCInfoToForm  -Control $WPFtxtSecurityInfo
        Get-SVCMemoryInfo | Convert-SVCInfoToForm  -Control $WPFtxtMemoryInfo
        Get-SVCStorageInfo | Convert-SVCInfoToForm  -Control $WPFtxtStorageInfo

        Get-BSODResults
        invoke-resultscheck

        Get-SVCDownloads
        $WPFWindowITComputerInfo.title = "SVC IT Computer Info"


    }
)



#$WPFWindowITComputerInfo
$WPFWindowITComputerInfo.ShowDialog() | Out-Null











break
















<#

Wish list: Convert to C# https://www.reddit.com/r/csharp/comments/sdbept/resourceswalkthroughs_for_converting_powershell/

Network Test KB Article linked in to help button.

Name check via subnet?




Windows defender real time protection



TDX API call :
    get TDX Asset ID
    Get TDX Asset Owner
    Get TDX Asset Status
    TDX Asset Tab?











function Invoke-FixUglyText {
    $FixCount = $($(Get-Clipboard ) -split [Environment]::NewLine ).count
    $FixLines = $(Get-Clipboard ) -split [Environment]::NewLine

    $( ForEach ($Line in $FixLines) {
            $i ++
            switch ($i) {
                1 { "`$Text `= `"$Line`"" }
                { $i -eq $FixCount } { "`$Text `+`= `"$Line`"" }
                Default { "`$Text `+`= `"$Line`"" }
            }
        } ) | Set-Clipboard
}





#>
