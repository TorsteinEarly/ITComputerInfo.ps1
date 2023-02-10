

#===========================================================================
# Memory
#  https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-physicalmemory
#===========================================================================

Function Get-SVCMemoryInfo {


    function get-WmiMemoryFormFactor {
        param ([uint16] $char)

        If ($char -ge 0 -and $char -le 22) {

            switch ($char) {
                0 { "Unknown" }
                1 { "Other" }
                2 { "SiP" }
                3 { "DIP" }
                4 { "ZIP" }
                5 { "SOJ" }
                6 { "Proprietary" }
                7 { "SIMM" }
                8 { "DIMM" }
                9 { "TSOPO" }
                10 { "PGA" }
                11 { "RIM" }
                12 { "SODIMM" }
                13 { "SRIMM" }
                14 { "SMD" }
                15 { "SSMP" }
                16 { "QFP" }
                17 { "TQFP" }
                18 { "SOIC" }
                19 { "LCC" }
                20 { "PLCC" }
                21 { "FPGA" }
                22 { "LGA" }
            }
        }

        else {
            "{ 0 } - undefined value" -f $char
        }
        Return
    }

    # Get the objects
    $memory = Get-WmiObject Win32_PhysicalMemory
    $TotalMemory = ( $memory | Measure-Object -Property capacity -Sum).sum / 1gb
    $NumberOfDIMS = Get-WmiObject Win32_physicalmemoryarray | Select-Object -ExpandProperty memorydevices
    $MemoryVoltage = ($memory.configuredvoltage | Select-Object -First 1) / 1000

    $MemoryUsage = (Get-WmiObject -Class WIN32_OperatingSystem |
        Select-Object @{
            Name = "MemoryUsage"; Expression = {
                [math]::round($((($PSitem.TotalVisibleMemorySize - $PSitem.FreePhysicalMemory) * 100) /
                        $PSitem.TotalVisibleMemorySize)) } # End Expression
        }
    ).MemoryUsage

    $MemoryTypeHeader = "Type"
    # Update this with DDR5... when M$oft updates their documentation
    # https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-physicalmemory

    $MemoryType = switch ($Memory.smbiosmemorytype[0]) {
        20 { "DDR" }
        21 { "DDR2" }
        22 { "DDR2 FB-DIMM" }
        { $Memory.smbiosmemorytype[0] -like 24 -and $MemoryVoltage -eq 1.5 } { "DDR3" }
        { $Memory.smbiosmemorytype[0] -like 24 -and $MemoryVoltage -eq 1.35 } { "DDR3L" }
        26 { "DDR4" }
        Default {
            "[SMBIOSMemoryType $PSitem] - Check manufacturer or installed memory"
            $MemoryTypeHeader = "[DDR#Unknown]"
        }
    }

    $ff = get-WmiMemoryFormFactor($memory.FormFactor[0])



    #======================================
    # Check for low memory
    #======================================
    if ( $TotalMemory -lt 8 ) {
        $Text = "Total memory is $TotalMemory GB. System performance will be impacted: "
        $Text += "Add more memory if slots are available. `n`n"
        Write-Results -color "Red" -text  "WARNING: " -text $Text
    }

    switch ($MemoryUsage) {
        { $PSitem -gt 75 } {

            $Restarted = ((Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime).days

            $MemUsageError = switch ($Restarted) {
                0 { "[Restarted Today]" }
                { $PSitem -ge 3 } { "[Restart to free up mem][Restarted $Restarted days ago]" }
                Default { "[Restarted $Restarted days ago]" }
            }


            $Text = $(
                "Memory usage is over 75%. System performance will be impacted. "
                "Try closing programs/browser tabs, or restarting your computer. `n`n"
            )
            Write-Results -color "Red" -bold -Header  "CRITICAL: " -text $Text
            $WPFbackMemory.background = $FormRed
            continue
        }
        { $PSitem -gt 60 } {
            $Text = "Memory usage is over 60%. System performance may be impacted. "
            $Text += "Try closing programs/browser tabs, or restarting your computer. `n`n"
            Write-Results -color "red" -Header  "WARNING: " -text $Text
            $WPFbackMemory.background = $FormYellow
        }
    } # End Switch

    # Output memory totals

    [pscustomobject]@{
        "Total Memory"    = "$TotalMemory GB"
        "Memory Usage"    = "$MemoryUsage%" + $MemUsageError
        "Slots Full"      = "$( If ($Null -like $memory.count ) { "1" }else { $Memory.count })"
        "Total Slots"     = "$NumberofDims"
        "Form Factor"     = "$ff"
        $MemoryTypeHeader = $MemoryType
        "Voltage"         = "{0}V" -f $MemoryVoltage
    }



    #===================================
    # Get memory hungry apps
    #===================================


    # Get all running process memory usage. grouped on name so as to merge the mem usage of duplicates.
    $Apps = (Get-Process |
        Group-Object -Property ProcessName |
        Select-Object Name,
        @{n = 'Mem'; e = { '{0:N0}' -f (($_.Group | Measure-Object WorkingSet -Sum).Sum / 1mb) } }
    )

    if ($Apps.name -contains "iexplore") {
        $Text = "Internet Explorer open! Internet Explorer is no longer supported and has many security vulnerabilities.`n"
        $Text += "Please only use Internet Explorer for websites that only support it; Use Edge, Chrome, or FireFox instead.`n`n"
        write-results -color 'red' -header "WARNING: " -text $Text
    }

    # Convert the memory string to an int so we can run math against it.
    $Apps | ForEach-Object { $PSitem.mem = [int]$PSitem.mem }



    $OSapps = "Memory Compression", "svchost", 'explorer', 'runtimebroker', 'wmiprvse', "dwm"
    $Apps = ($Apps | Sort-Object mem -Descending |
        Where-Object { $PSitem.name -notin $OSApps -and $PSitem.mem -gt 500 }
    )

    # Write the output for the top hungry apps
    $Output = [pscustomobject]@{"Header1" = "Top Memory Hungry Applications" }
    $Apps | ForEach-Object {
        $MemError = ""
        if ($PSitem.name -in "Chrome", "msedge", "FireFox", "iexplore") { $MemError = "[X tabs to free mem]" }
        if ( $PSitem.name.length -ge 14) { $PSitem.name = $PSitem.name[0..12] -join "" }
        $Output | Add-Member -MemberType noteproperty -Name $PSitem.Name -Value "$($PSitem.mem) MB $MemError"
    }


    $Output


    #==================================
    # Process each memory stick
    #==================================

    Foreach ($stick in $memory) {

        # Do some conversions
        $cap = $stick.capacity / 1GB

        [pscustomobject]@{ # output details of each stick
            "Slot"         = "$($stick.DeviceLocator)"
            "Capacity"     = "$cap GB"
            "Speed"        = "$($stick.Speed) MHz"
            "Manufacturer" = $Stick.Manufacturer
            "Part #"       = $Stick.PartNumber
            "Serial #"     = $Stick.serialnumber
        }


    } # End for each stick


} # End Memory




