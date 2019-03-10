Connect-VIServer itgaiden.pokemon.jp -User administrator@vsphere.local -Password VMware1!

Import-Module "C:\Github_repo\InstantClone.psm1"


$SnapShot = New-Snapshot -VM $BaseVM -Name "Linked-Snapshot-for-$TargetVMs" -Description "Snapshot for linked clones for $TargetVM" -Memory -Quiesce
    Write-Host "Snapshot create on $BaseVM" -ForegroundColor Green

#-------------------------------------------------------------------------------------
#Customization Spec creation (will ask for Domain user and password)

New-OSCustomizationSpec -Name 'PCLI' -FullName 'FullName' -OrgName 'TestOrg' -Type Persistent -OSType Windows -ChangeSid -Server 'itgaiden.pokemon.jp' -AdminPassword 'VMware1!' -Domain 'pokemon.jp' -TimeZone 090 -DomainCredentials (Get-Credential) -AutoLogonCount 1

$OSSpec = Get-OSCustomizationSpec -Name 'PCLI'
New-OSCustomizationNicMapping -IpMode 'UseStaticIP' -OSCustomizationSpec $OSSpec -IpAddress '192.168.1.168' -SubnetMask '255.255.255.0' -Dns '192.168.1.195' -DefaultGateway '192.168.1.1'
##****************************
##If you want to remove any Nic Mapping
##Get-OSCustomizationNicMapping –OSCustomizationSpec $OSSpec | where {$_.Position –eq 1} | Remove-OSCustomizationNicMapping
##***************************
# Setting OS Specification variable (it has no NIC mapping assigned)



# nic mapping

$nicMapping = Get-OSCustomizationNicMapping –OSCustomizationSpec $OSSpec
$nicMapping | Set-OSCustomizationNicMapping -Position 1 –IpMode UseStaticIP –IpAddress '192.168.1.169' –SubnetMask '255.255.255.0' -Dns '192.168.1.195' -DefaultGateway '192.168.1.1'

#-------------------------------------------------------------------------------------------

# Creating Regular Clone

New-VM -Name "PCLIClone" -VM "W2016_test" -Datastore "QNAP_Datastore" -VMHost "johto.pokemon.jp" -OSCustomizationSpec $OSSpec
Start-VM -VM PCLIClone


# Linked Clone:
New-VM -Name $TargetVM -VM $BaseVM -Datastore $TargetDatastore -VMHost $VMhost 
-LinkedClone -ReferenceSnapshot $SnapShot

# Creating Linked Clone
New-VM -Name "Linked_PowerCLIClone" -VM "W2016_test" -Datastore "QNAP_Datastore" -ResourcePool (Get-Cluster -Name RyuCluster | Get-ResourcePool) -OSCustomizationSpec $OSSpec -LinkedClone -ReferenceSnapshot "OS"
