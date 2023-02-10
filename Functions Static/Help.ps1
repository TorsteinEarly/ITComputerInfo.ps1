

$WPFtxbResults.Document.Blocks.Clear()
# This whole section is such a pain. It look nice in the results textbox though though...
# I should probubly just write this to a text file and open it with notepad...

$Text = "Please send Notes/Warnings/Failures to the Help Desk. "
$Text += "Send app questions and unexpected results to TE@skagit.edu.`n`n"
Write-Results -color 'purple' -bold -header $Text



$Text = "`nYellow indicates a warning was generated in this section.`n"
$Text += "Red indicates a critical warning was generated in this section."
write-results -color 'black' -bold -header "`n`nColors: " -text $Text



#======================================
# Buttons
#======================================
write-results -color 'black' -bold -header "`n`n`n`nButtons: "

$Text = "Double Click to open System Properties to rename or join/disjoin the domain. "
write-results -color 'black' -bold -header "`n`nFQDN: " -text $Text


$Text = "Redisplay the warnings and reevaluate "
$Text += "basic/network/memory/security/storage info in the case that you have changed any settings."
write-results -color 'black' -bold -header "`n`nReload Info: " -text $Text

$Text = "Copy all info generated via the tool. If the network test "
$Text += "has been run, the network test results will also be copied. "
$Text += "Please send these to the Help Desk in the event that you are having a computer issue. "
write-results -color 'black' -bold -header "`n`nCopy Info: " -text $Text







#======================================
# Computer Basics
#======================================
write-results -color 'black' -bold  -header "`n`n`n`nComputer Basics: "

$Text = "Fully Qualified Domain Name, or the Computer name and the Domain "
$Text += "Name of the computer. Best to use the FQDN over the computer name when possible."
write-results -color 'black' -bold  -header  "`n`nFQDN: " -text  $Text

$Text = "The user account logged in to this computer. Or the user you ran "
$Text += "the tool as if you ran it as another user."
write-results -color 'black' -bold  -header  "`n`nCurrent User: " -text   $Text

$Text = "If on SVC Networks, lists the active directory orgonizational unit of the computer. "
$Text += "The computer needs to be in the right OU to ensure it gets the correct network policy."
write-results -color 'black' -bold  -header  "`n`nAD OU: " -text   $Text

$Text = "The SVC State Tag (old tags are 4 or 5 numbers, new tags are Snnnnnnnn) or ''C'' Tag "
$Text += "(Cnnnnnnnn) that the business office uses for State Inventory, or the silver ''IT'' "
$Text += "inventory tag. This should be entered in the TDX Asset under the Service Tag field, "
$Text += "as well as the Asset field in the computer bios."
write-results -color 'black' -bold  -header  "`n`nAsset Tag: " -text  $Text

$Text = "The CompositionEditionID and Sku number of the Windows Version. Both indicate which features are "
$Text += "available, as well as what version of windows is required for upgrading. We typically run "
$Text += "Enterprise. SKU info: "
$Text += "https://docs.microsoft.com/en-us/dotnet/api/microsoft.powershell.commands.operatingsystemsku?view=powershellsdk-1.1.0 "
write-results -color 'black' -bold  -Header "`n`nCompEditionID/Sku: " -text $Text

$Text = "https://docs.microsoft.com/en-us/windows/release-health/release-information"
write-results -color 'black' -bold  -header  "`n`nOS Version: " -text  $Text

$Text = "The last time the computer turned on. "
$Text += "They like to be restarted frequently. Please be nice to them."
write-results -color 'black' -bold  -header  "`n`nStartup: " -text  $Text







#======================================
# Network Tab
#======================================
write-results -color 'black' -bold  -header   "`n`n`n`nNetwork Tab: " -text   '
This section is structured like:
        - Physical Address (MAC)
        - IP Address or Addresses assigned to the above MAC.

If a MAC has multiple IP Addresses, they will be listed as VLANS under said MAC.'

$Text = 'Lower is higher priority. If you have multiple adapters or VLANS you
should set your primary as the lowest interface metric. Wi-Fi should
always be higher than LAN (IE, LAN is the priority and has a lower
interface metric), as is usually done automatically.
https://docs.microsoft.com/en-us/troubleshoot/windows-server/networking/automatic-metric-for-ipv4-routes'
write-results -color 'black' -bold  -header   "`n`nInt Metric: " -text  $Text

$Text = "This is the DNS network name supplied by DHCP. It is Not the Active Directory Domain "
$Text += "that the computer is joined to. If on an SVC network, know that mysvc (student networks) "
$Text += " and WiFi may not have access to all employee resources."
write-results -color 'black' -bold -header "`n`nDNS Domain: " -text $Text

$Text = "Runs basic network and internet conectivity tests, as well as SVC network spesific tests. "
$Text += "Results should be interpreted by a network technician. Currently in Beta; "
$Text += "it works but has not been tested during every type of outage."
write-results -color 'black' -bold -header "`n`nTest Network Button: " -text $Text

$Text = "Should the computer have lost it's trust relationship with the domain, you can use  "
$Text += "this tool to attempt to fix the trust relationship. Requires both local and network access."
write-results -color 'black' -bold -header "`n`nFix Trust Relationship button: " -text $Text







#======================================
# Security Tab
#======================================
write-results -color 'black' -bold  -header  "`n`n`n`nSecurity Tab: "


$Text = "The first is for periodic scanning, which can still"
$Text += "be manually enabled when the `"real`" defender AV is disabled due"
$Text += "to another AV like SentinelOne acting as the primary. `n"
$Text += "The second listing is other defender settings that stay enabled when S1 is installed. "
$Text += "When in doubt, ignore the AV settings and open the actual AV applet"
$Text += "to find it's status and versions. It once thought SEP was"
$Text += "installed... It was not. So that WMI class can get stale."
write-results -color 'black' -bold  -header "`n`nWhy is Defender listed twice?: " -text  $Text


$Text = "Generally the firewall should be enabled on client computers. If it is dissabled,  "
$Text += "the computer may have malware on it. `nIf it was dissabled for a reason, ."
$Text += "you are better off finding the applications/ports to allow through the firewall."
write-results -color 'black' -bold -header "`n`nWindows Firewall Status: " -text $Text






#======================================
# Memory Tab
#======================================
write-results -color 'black' -bold -header "`n`n`n`nMemory Tab: "

$Text = "DIMM is the full size memory card that is typical of desktops. "
$Text += "SODIMM is the half size memory card typical of laptops and small "
$Text += "form factor machines. Google other strange values. "
$Text += " https://docs.microsoft.com/en-us/windows/win32/cimwin32prov/win32-physicalmemory"
write-results -color 'black' -bold -header  "`n`nForm Factor: " -text $Text


$Text = "Normally you only need to know the speed, type (DDR3/DDR4) and form "
$Text += "factor (DIMM/SODIMM) to find compatible memory. `n "
$Text += "When in doubt, look up the computer model specifications on the "
$Text += "manufacturer website to see memory spesifics; it may be that you can run a faster speed!"
write-results -color 'black' -bold  -header  "`n`nBuying more memory: " -text  $Text



#======================================
# Storage Tab
#======================================

write-results -color 'black' -bold -header "`n`n`n`nStorage Tab: "

$Text = "In the event that your storage is filling up, try disk cleanup and removing downloads. "
$Text += "if you are still low on space, try downloading WinDirStat to visualize large files on the disk."
$Text += "https://windirstat.net/"
write-results -color 'black' -bold -header  "`n`nLow Storage Space: " -text $Text

$Text = "Indicates a drive that has bad sectors/corupted data: run check disk if not healthy."
write-results -color 'black' -bold -header  "`n`nHealth: " -text $Text




