function Get-BSODResults {


    Get-EventLog -LogName application -Newest 100 -Source 'Windows Error*' |
    Where-Object message -Match 'bluescreen' |
    ForEach-Object {

        $Param = @{
            bold   = $True
            color  = 'blue'
            header = "Recent BSOD: "
            text   = "$($PSitem.TimeWritten)`nMessage: $($PSitem.Message )`n`n"
        }

        write-results @Param
    }





} # End function

