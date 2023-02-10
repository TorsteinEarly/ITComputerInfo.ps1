function invoke-svccopy { 
    $(        "`nComputer:::::::::::::::::::::::::::::::::::::::::: ",
        $WPFtxtComputerInfo.Text,
        "`nNetwork:::::::::::::::::::::::::::::::::::::::::",
        $WPFtxtNetworkInfo.Text,
        "`nMemory:::::::::::::::::::::::::::::::::::::::::: ",
        $WPFtxtMemoryInfo.Text ,
        "`nAV::::::::::::::::::::::::::::::::::::::::::",
        $WPFtxtSecurityInfo.Text ,
        "`nNotes:::::::::::::::::::::::::::::::::::::::::: ",
        $ResultsCopy ,
        $(
            if ( $NetworkTestResults ) { 
                "`nNetwork Test Results:::::::::::::::::::::::::::::::::::::::::: "
                $NetworkTestResults
            }
        )             )  | Set-Clipboard   
    
    $WPFtxbResults.Document.Blocks.Clear()
    Write-Results -color "Black" color -orange -Header "

... ... ... ... ... ... ... ... ... ... ... ... ... " -text "
        Results copied to your clipboard for easy access to send to the IT Help Desk via email or online ticket. "
        
    
         
    $WPFbtnCopy.Background = "#FF9ADE90"
    $WPFbtnCopy.content = "Copied"

    

}