
if ($WPFbtnDownloadCleanup.content -like "Clear All Users Downloads") {

    $Username = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name.split("\")[1]

    $Text = $( "The download files in c:\users\$($Username)\downloads is under 100 MB, "
        "which is inconsequential. Would you instead like to delete all users download files?"
        "This will require admin rights.`n`n"
        "      Yes: Delete files in all users downloads.`n`n"
        "      No: Stop program."
    )
    $Result = $shell.popup($Text, 0, "Cleaning Downlads:", $ShowOnTop + $Icon.stop + $Buttons.YesNo)
       
    if ($clickedButton.$Result -like "Yes") {

        # Save the script. 
        $(
            'Get-ChildItem -Path "c:\users\" -Directory |'  
            'ForEach-Object {'
            'Get-ChildItem -Path "$($PSitem.fullname)\downloads" -Include *.* -File -Recurse -erroraction silentlycontinue}'
            'write-host -ForegroundColor Yellow "`n Are you sure you want to delete all these files????"'
            'write-host -ForegroundColor Yellow "`n yes: delete the files."'
            'write-host -ForegroundColor Yellow "`n no: exit."'
            'do {'
            '    switch (Read-Host "`n Type yes or no and press enter") {'
            '        "no" {'
            '            "`n No Files Deleted. Exit in 15 seconds, or you can close this window"' 
            '            $Success = $True '
            '            Start-Sleep 15'
            '        } # End No'
            '        "yes" {' 
            '            "`n Deleting files..." '
            '            $Success = $True '
            '$Users = Get-ChildItem -Path "c:\users\" -Directory '  
            'ForEach ($User in $Users) {'
            'Get-ChildItem -Path "$($User.fullname)\downloads" -Include *.* -File -Recurse -erroraction silentlycontinue |'
            'ForEach-Object { $_.Delete() }'
            '   } # End foreach user'
            'Write-Host -ForegroundColor Yellow "`n Files deleted. Script will exit in 15 seconds, or you can close this window"'
            'Start-Sleep 15'
            '        } # End Yes'
            '        default {write-host -foregroundcolor red "`nInvalid entry: Type yes or no and press enter." }'
            '    } # End Switch'
            '} until ($Success -like $True) # End Do Until... '

        ) | Out-File "$env:temp\KillAllDownloads.ps1"

          

        # Call the script as admin. Form must be hidden
        $Form.hide()
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('
            -noprofile  -file "{0}" -elevated' -f "$env:temp\KillAllDownloads.ps1")
        $Form.ShowDialog()
        Remove-Item "$env:temp\KillAllDownloads.ps1" -ErrorAction SilentlyContinue

 

 
    } # end if yes click on dialog box
            
           
} # End if button all users
else {
    # Clear just this user
    $WPFtxbResults.Document.Blocks.Clear() # clear previous results
    write-results -bold -color 'purple' -header "Files in c:\users\$($Username)\downloads:" -text "`n"
    write-results -bold -header "Last Write Time - Name: `n"

    Get-ChildItem c:\users\$($Username)\downloads | 
    Sort-Object -Property LastWriteTime -Descending |
    ForEach-Object {
        $LastWriteTime = $($($PSitem.LastWriteTime).ToShortDateString())
        write-results -color 'black' -header '' -text "$LastWriteTime - $($PSitem.Name)`n" 
    }


    $Text = $( "Are you sure?`n`n"
        "This will permenatly delete all files in user $($Username) downloads folder."
        "These files are saved from web browsers, and are often used once and not needed later.`n`n"
        "You may want to first open c:\users\$($Username)\downloads `n"
        "to check for files you want to keep; move them to your department drive or documents folder.`n`n"
        "      Yes: Delete files in $($Username)'s downloads.`n`n"
        "      No: Stop program so you can go move files first."
    )
    $Result = $shell.popup($Text, 0, "Cleaning Downlads:", $ShowOnTop + $Icon.stop + $Buttons.YesNo)

    if ($clickedButton.$Result -like "Yes") {
        $UserDownloadsSize = ((Get-ChildItem c:\users\$($Username)\downloads | 
                Measure-Object -Property length -Sum -ErrorAction SilentlyContinue).sum / 1gb
        ) 
        Get-ChildItem -Path "c:\users\$Username\downloads" -Include *.* -File -Recurse | 
        ForEach-Object { $_.Delete() }
        $Text = "Files at c:\users\$Username\downloads deleted. $UserDownloadsSize GB storage recovered."
        $shell.popup($Text, 0, "Cleaning Downlads:", $ShowOnTop + $Icon.stop + $Buttons.YesNo)
        Get-SVCDownloads

    }
    else {
        $Text = "No Downloads Deleted."
        $shell.popup($Text, 0, "Cancel Cleaning Downlads:", $ShowOnTop + $Icon.information + $Buttons.ok)
    }



} # End if all users / else this user 