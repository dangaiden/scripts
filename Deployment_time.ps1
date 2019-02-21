Import-Module InstantClone.psm1
 
$SourceVM = "UbuntuVM"
 
$numOfVMs = 2
$ipNetwork = "192.168.30"
$ipStartingCount=50
$netmask = "255.255.255.0"
$dns = "192.168.1.150"
$gw = "192.168.1.1"
 
$StartTime = Get-Date
foreach ($i in 1..$numOfVMs) {
    $newVMName = "Instant-$i"
 
    $guestCustomizationValues = @{
        "guestinfo.ic.hostname" = "$newVMName"
        "guestinfo.ic.ipaddress" = "$ipNetwork.$ipStartingCount"
        "guestinfo.ic.netmask" = "$netmask"
        "guestinfo.ic.gateway" = "$gw"
        "guestinfo.ic.dns" = "$dns"
        "guestinfo.ic.sourcevm" = "$SourceVM"
    }
    $ipStartingCount++
    New-InstantClone -SourceVM $SourceVM -DestinationVM $newVMName -CustomizationFields $guestCustomizationValues
}
 
$EndTime = Get-Date
$duration = [math]::Round((New-TimeSpan -Start $StartTime -End $EndTime).TotalMinutes,2)
 
Write-Host -ForegroundColor Cyan  "`nTotal Instant Clones: $numOfVMs"
Write-Host -ForegroundColor Cyan  "StartTime: $StartTime"
Write-Host -ForegroundColor Cyan  "  EndTime: $EndTime"
Write-Host -ForegroundColor Green " Duration: $duration minutes"