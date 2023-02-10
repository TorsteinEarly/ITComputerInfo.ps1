

$WPFtxbResults.Document.Blocks.Clear() # clear previous results
$Text = $("`n`nDisk Cleanup may open behind other windows. "
    "If you do not see it, look for the blinking icon on your taskbar, " 
    "or minimize other windows till you find it.`n`n"
    "Check every box in Disk Cleanup, then click the OK button to start cleaning.`n`n"
    "If you are an IT Technician, fist click the Clean up system files button. `n`n"
    "Reload results in the IT Computer Info tool once you have finished disk cleanup."
)
write-results -bold -color 'purple' -header "Starting Disk Cleanup: " -Text $Text
    
# Clean mgr will open behind the form.
# And the form prevents us from pulling clean mgr to the front
# so we need to spin up another powershell process to pull clean mgr to the front
# but the form prevents another the other PS proc while the form is shown
# so we hide the form, spin up a PS script, and then show the form again.
# and the form will just pop back up over clean mgr when we reshow the form
# So we need to delay the powershell script so that the form can show again. Oii.

$Form.hide()
cleanmgr.exe
    
' (New-Object -ComObject WScript.Shell).AppActivate((Get-Process cleanmgr).MainWindowTitle)
    write-host "`n just trying to bring clean mgr to front. That is all" -foregroundcolor yellow
    Start-Sleep 2 # allow the form to come back up first
    (New-Object -ComObject WScript.Shell).AppActivate((Get-Process cleanmgr).MainWindowTitle)
    ' |    Out-File "$env:temp\ShowCleanMgr.ps1"
Start-Process powershell.exe -ArgumentList ('
    -noprofile  -file "{0}" ' -f "$env:temp\ShowCleanMgr.ps1")
    
$Form.ShowDialog()
Start-Sleep 2
Remove-Item "$env:temp\ShowCleanMgr.ps1" -ErrorAction SilentlyContinue
