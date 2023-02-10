
# Confirmation dialog
$Text = $(
    "Do you want to schedule a disk check to fix bad sectors on disk?`n`n"
    "This will run at next start up and take at least an hour.`n`n"
    "This will require admin rights.`n`n"
    "      Yes: Schedule Disk Check.`n`n"
    "      No: Stop program."
)
$Result = $shell.popup($Text, 0, "Schedule Disk Check?:", $ShowOnTop + $Icon.Question + $Buttons.YesNo)

if ($clickedButton.$Result -like "Yes") {

    $WPFtxbResults.Document.Blocks.Clear() # clear previous results

    $Text = $(
        "Please inform the user that the disk check will run during next start up and take an hour or more. `n`n"
        "Reccomend that they restart their computer at the end of their shift. "
        "This will ensure that the check disk will run while they are not using the computer."
    )
    write-results -bold -color 'purple' -header "Check Disk Scheduled: " -text $Text 


    $Script = 'Write-Host "`n`n Scheduling Disk Check: When prompted, type Y and press enter on your keyboard.`n" -ForegroundColor yellow' 

    Get-SVCStorageInfo -CleanVolumes | ForEach-Object {
        $Script += "`nchkdsk $PSitem`: /b /x "
        $Script += "`nPause"
    } 
    $Script | Out-File "$env:temp\CleanVolumes.ps1"

  

    # Call the script as admin. Form must be hidden
    $Form.hide()
    Start-Process powershell.exe -Verb RunAs -ArgumentList ('
    -noprofile  -file "{0}" -elevated' -f "$env:temp\CleanVolumes.ps1")
    $Form.ShowDialog()
    Remove-Item "$env:temp\CleanVolumes.ps1" -ErrorAction SilentlyContinue

        

} # end if yes click on dialog box