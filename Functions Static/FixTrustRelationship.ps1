
if ( $WPFbtnFixTrust.Content -like "Trust: Workgroup"
) {
    $Text = '
  Oops! The computer is not joined to a Domain:

  1: Run/search for sysdm.cpl in the start menu, or double click the FQDN the IT Computer Info Tool.
  2: Click the Change button.
  3: Join the machineto the mv.skagit.edu or mysvc.skagit.edu domain.
  4: You may be asked to eneter your tech network admin username an password.
  5: Restart the computer
  6: In active directory, move the computer account to the correct OU.
     '
    $shell.popup($Text, 0, "Workgroup Computer:", $ShowOnTop + $Icon.Question + $Buttons.ok)

    return
}



# Notes in results
$WPFtxbResults.Document.Blocks.Clear() # clear previous results

$Text = $(

    "$(
        if (Test-ComputerSecureChannel ) {
            $Color = 'green'
            "Computer Account Trusted By AD: [Test Pass]"
    } else {
        $Color = 'red'
            "Computer Account Not Trusted By AD: [Test Failed or off SVC Net]."
        }
    )"
    [System.Environment]::NewLine ; [System.Environment]::NewLine

    'You will be asked authenticate because a program is making changes to the computer:'
    "Click the Yes buton, or enter $Env:Computername\svcadmin and the password and press yes."
    [System.Environment]::NewLine ; [System.Environment]::NewLine
    'Once in the new powershell window, you will again be asked to enter a username and password:'
    'Enter your IT Technician Admin username and password, like mv\thor and LAPS password.'
    [System.Environment]::NewLine ; [System.Environment]::NewLine
    'If the reset command fails, ensure that there is a computer account in active directory '
    'with the same name as this computer. If there is not, you can either create one and rerun '
    'the reset command, or disjoin and rejoin this computer: Run/Start menu sysdm.cpl '
    'and click the change button.'
    [System.Environment]::NewLine ; [System.Environment]::NewLine

)
Write-results -bold -color $Color -header "Trust Relationship: " -Text $Text


# Confirmation dialog
$Text = $(
    "Attempting to fix domain trust relationship.`n`n"
    "The first dialog box after this will be a UAC box asking to make changes to your computer. "
    "If asked for a username and password with this box, it will be for local admin rights, "
    "ie $env:computername\svcadmin.`n`n"
    "Once in the script, you will again be asked for a username and password "
    "to reconnect to the domain; use your technician network admin account.`n`n"
    "      OK: Fix Trust.`n`n"
    "      Cancel: Stop program."
)
$Result = $shell.popup($Text, 0, "Fix Domain Trust", $ShowOnTop + $Icon.Question + $Buttons.OkCancel)

if ($clickedButton.$Result -like "Ok") {




    $Script = {

        try {
            $TechAdmin = Get-Credential -Message "Enter your technician network username and password like MV\username and [password]"

            Reset-ComputerMachinePassword  -Credential $TechAdmin

            $Iterations = 0
            $SVCStop = $False
            do {

                $Iterations ++

                if ($Iterations -eq 10
                ) {
                    $Iterations = 0
                    $ReadHost = Read-Host "
                You have been waiting for awhile.

                Press enter to continue testing, or
                Type Stop to stop testing: "

                    if ($ReadHost -like "Stop"
                    ) {
                        $SVCStop = $True
                        Write-Host "Stopping check: Unable to fix trust.
        Confirm that there is an account in AD with this computers name and try again.
        Or disjoin and rejoin the computer to the domain using sysdm.cpl`n" -ForegroundColor yellow

                    }
                } # End iterate for a minute check


                if (Test-ComputerSecureChannel
                ) {
                    $SVCStop = $True
                    Write-Host "
        Success! Trust Restored. Please restart." -ForegroundColor Yellow

                }
                Else {
                    Write-Host "Still waiting on the DC to send a response.`n" -ForegroundColor Yellow
                    Start-Sleep 10
                }
            } while ( $SVCStop -like $False)

        }
        catch {
            $thisError = $_
            Switch -wildcard ($thisError.Exception) {
                "*The server is not operational.*" {
                    Write-Host  "
                        Oops! The DC cannot be located.

                        If you are off of the SVC network, this is to be expected; first connect to VPN.

                        If you are on the SVC network, then there is a possible DC outage." -ForegroundColor yellow
                }
                "*Cannot find the computer account*" {
                    Write-Host  "
                        Oops! There is no computer account for this computer in the domain.

                        1: Run/search for sysdm.cpl in the start menu, or double click the FQDN the IT Computer Info Tool.
                        2: Click the Change button.
                        3: Disjoin the machine by changing it to any workgroup and clicking ok.
                        4: You may be asked to eneter your tech network admin username an password.
                        5: Click the change button again. Rejoin the domain you just left.
                        6: Restart the computer
                        7: In active directory, move the computer account to the correct OU.
                          " -ForegroundColor yellow
                }
                Default {
                    Write-Host  "unknown exception" -ForegroundColor yellow
                    Throw $_
                }
            }  # End error switch
        }# End try catch

        Pause # After everything to ensure that any selection/error will get paused

    }  # End script block






    $Script.ToString() | Out-File "$env:temp\FixTrust.ps1" -Encoding utf8



    # Call the script as admin. Form must be hidden
    $Form.hide()
    Start-Process powershell.exe -Verb RunAs -ArgumentList ('
    -noprofile  -file "{0}" -elevated' -f "$env:temp\FixTrust.ps1")
    $Form.ShowDialog()
    Remove-Item "$env:temp\fixtrust.ps1" -ErrorAction SilentlyContinue






} # End button OK check















