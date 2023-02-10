

Function Get-SVCStorageInfo {
    Param([switch]$CleanVolumes = $false )


    $Disks = ( Get-Disk )
    $Volumes = ( Get-Volume |
        Where-Object {
            $Null -NotLike $PSitem.DriveLetter -and # Skip hidden partitions.
            $PSitem.DriveType -notlike "CD-ROM" -and
            $PSitem.size -gt 0 # skip floppy and other strange oddities
        }
    ) # end get volume

    ForEach ($Disk in $Disks) {

        $DiskID = $Disk.ObjectId.Split("{}")[3]

        if ($CleanVolumes -NOTlike $True) {
            # Output the disk info from the function
            [pscustomobject]@{
                "Disk Number"  = $Disk.DiskNumber
                "Manufacturer" = $Disk.Manufacturer
                "Model"        = $Disk.Model
                "Type"         = $(Get-PhysicalDisk).mediatype
                "Size"         = "$([math]::Round($Disk.size / 1GB,2)) GB"
                "Boot Disk"    = $Disk.IsBoot
                "System"       = $Disk.IsSystem
            }
        } # end if volumes not cleaning


        #====================================
        # get info on each drive on the disk
        #====================================

        $Volumes |
        Where-Object { $PSitem.objectid.Split("{}")[3] -Like $DiskID
        } |
        ForEach-Object {

            if ($CleanVolumes -like $True) {

                if ($PSitem.HealthStatus -Notlike "Healthy") {
                    $PSitem.DriveLetter
                    # this is getting unhealthy drives
                    # and outputing the drive letter to the invoke-svccheckdisk disk function...

                }


            } # End clean volume
            else {
                # get size info
                $DriveLetter = $PSitem.DriveLetter
                $VolumeSize = "$([math]::Round( $PSitem.Size / 1GB, 2 ) ) GB"
                $VolumeSizeRemaining = [math]::Round( $PSitem.SizeRemaining / 1GB, 2 )
                $Text = "$($DriveLetter)`:\ Drive free space [ $VolumeSizeRemaining GB remaining ] is low. "
                $Text += "Run Disk Cleanup and delete old files from downloads. If storage is still low, "
                $Text += "consider downloading WinDirStat to view large files that can be deleted.`n`n"

                # For real disks, check for low space:
                # Filter these out because they are "low" on space by design
                if ($PSitem.FileSystemLabel -match 'Recovery' -or
                    $PSitem.FileSystemLabel -match 'System') {
                    $VolumeSizeRemaining = "$VolumeSizeRemaining GB"
                }
                else {
                    # Check for low space
                    switch ($VolumeSizeRemaining) {
                        { $VolumeSizeRemaining -lt 20 } {
                            $VolumeSizeRemaining = "$VolumeSizeRemaining GB: CRITICALLY LOW"
                            Write-Results -color 'red' -bold -header 'CRITICAL: ' -text $Text
                            $WPFbackStorage.background = $FormRed
                            Continue
                        }
                        { $VolumeSizeRemaining -lt 50 } {
                            $VolumeSizeRemaining = "$VolumeSizeRemaining GB: Low Space"
                            Write-Results -color 'red' -header 'WARNING: ' -text $Text
                            $WPFbackStorage.background = $FormRed
                            Continue
                        }
                        Default { $VolumeSizeRemaining = "$VolumeSizeRemaining GB" }
                    } # End Volume Switch
                } # End if a real drive or a system/recovery drive.

                if ($PSitem.HealthStatus -NOTlike "Healthy") {
                    $Text = "$DriveLetter`:\ Drive health is $($PSitem.HealthStatus). Schedule Check Disk.`n`n"

                    write-results -color 'red' -header 'WARNING: ' -text $Text
                }

                # Output the volume information from the function for real drives
                # filtering these out here let us still check for unhealthy drives above
                # without putting the unhelpful info in the info tab.
                if ($PSitem.FileSystemLabel -NOTmatch 'Recovery' -and
                    $PSitem.FileSystemLabel -NOTmatch 'System') {
                    [pscustomobject]@{
                        " Drive"       = $PSitem.DriveLetter + ':\'
                        " Drive Label" = $PSitem.FileSystemLabel
                        " File System" = $PSitem.filesystem
                        " Health"      = $PSitem.HealthStatus
                        " Size"        = $VolumeSize
                        " Remaining"   = $VolumeSizeRemaining
                    }
                }
            } # End if/else clean volumes




        } # End volumes for each
    } # End Disks for each

} # End IT Storage Info function







Function Get-SVCDownloads {

    $Username = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name).split("\")[1]

    $UserDownloadsSize = ((Get-ChildItem c:\users\$($username)\downloads |
            Measure-Object -Property length -Sum -ErrorAction SilentlyContinue).sum / 1gb
    )

    if ($UserDownloadsSize -gt 0.1) {
        $WPFbtnDownloadCleanup.content = "Clear Downloads [ {0:N} GB ]" -f $UserDownloadsSize
    }
    Else {
        $WPFbtnDownloadCleanup.content = "Clear All Users Downloads"

    }
}


