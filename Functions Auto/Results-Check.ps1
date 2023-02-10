




#===========================================================================
# Results Check
#===========================================================================
function invoke-resultscheck {



    # End error/warning check
    # Get contents from the richtextbox results.
    [System.Windows.Forms.RichTextBoxStreamType]::PlainText
    $ResultsRange = New-Object System.Windows.Documents.TextRange(
        $WPFtxbResults.Document.ContentStart, $WPFtxbResults.Document.ContentEnd )

    # Count the Warnings.
    [regex]$regex = 'WARNING'
    $WarningCount = $regex.matches($ResultsRange.text).count


    if ( # Only tell them to contact the help desk if there is a warning that is Not about computer uptime.
        ($WarningCount -gt 0 -and $DaysSinceStartup -lt 5) -or
        ($WarningCount -gt 1 -and $DaysSinceStartup -ge 5) -or
        ($ResultsRange.text -like "* Critical*")
    ) {
        # Write-Results -color "Black" -bold -header "Please contact the IT Help Desk about these warnings.`n"

    }

    $script:ResultsCopy = $ResultsRange.text.Clone()
} # End results check

