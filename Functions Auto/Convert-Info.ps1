function Convert-SVCInfoToForm {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        $Control,
        [Parameter(Mandatory, ValueFromPipeline)]
        $Info
    )
    Begin {
        $Control.text = "" # Clear the text from the box for any subsequent runs.
    }
    Process {
        $Properties = $Info.psobject.Properties.name
        ForEach ( $Property in $Properties ) {

            # decide when to add new lines and when to add properties/values
            switch ($Property) {
                { $Property -like "BlankLine*" } {
                    $Control.addtext($([system.environment]::NewLine))
                }
                { $Property -like "Header*" } {
                    $Control.addtext($Info.$Property + $([system.environment]::NewLine))
                }
                Default {
                    # Add spaces so the values align.
                    $PropertyFixed = $Property
                    do {
                        $PropertyFixed += " "
                    }while ( $PropertyFixed.length -lt 14 )

                    $Control.addtext("$PropertyFixed`: $($Info.$Property)" + $([system.environment]::NewLine))
                } # End default
            } # End Switch

        } # End ForEach property name

        # Add a blank line after the object
        $Control.addtext($([system.environment]::NewLine))



    } # End Process Block
    end {
        $Control

    }

} # End Convert-SVCInfoToForm function



