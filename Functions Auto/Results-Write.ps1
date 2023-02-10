

Function Write-Results {
    Param(
        [string]$text,
        [string]$Header,
        [string]$color,
        [switch]$Bold = $false
    )
    if ($Null -like $Color) { $color = 'black' }

    $FullText = @{
        0 = $Header
        1 = $Text
    }

    for ($i = 0; $i -lt 2; $i++) {

        $ResultsRange = New-Object System.Windows.Documents.TextRange(
            $WPFtxbResults.Document.ContentEnd, $WPFtxbResults.Document.ContentEnd )
        $ResultsRange.Text = $FullText.$i

        if ($i -eq 0 ) {
            $ResultsRange.ApplyPropertyValue( ( [System.Windows.Documents.TextElement]::ForegroundProperty ), $color )
            If ($Bold -like $True) {
                $ResultsRange.ApplyPropertyValue( ( [System.Windows.Documents.TextElement]::FontWeightProperty ), "Bold" )
            }
            else { $ResultsRange.ApplyPropertyValue( ( [System.Windows.Documents.TextElement]::FontWeightProperty ), "Normal" ) }
        }
        else {
            $ResultsRange.ApplyPropertyValue( ( [System.Windows.Documents.TextElement]::ForegroundProperty ), 'black' )
            $ResultsRange.ApplyPropertyValue( ( [System.Windows.Documents.TextElement]::FontWeightProperty ), "Normal" )
        } # end if i eq 0
    } # end for
} # End Write Results


