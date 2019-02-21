<#
.SYNOPSIS
    A Scirpt to create a linked clone in VMware vSphere.
     
.DESCRIPTION
    This script will take a snapshot of a Base VM (VM to becloned) and create new linked clone(s) from the snapshot. Linked clones use less storage since they only save the delta data. Instead of copying all data.
    This script allows you to create multiple linked clones from one base snapshot. The script also checks if there isn't a snapshot for the linked clones alreday present on the BaseVM. 
 
.NOTES
    File Name  : New-VMLinkedClone.ps1
    Author     : Chris Twiest - chris.twiest@dtncomputers.nl
    This script uses VMware PowerCLI make sure to install PowerCLI before running the script.
 
.LINK
    https://workspace-guru.com

.FUNCTION PARAMETERS EXPLANATION
    vCenterserver          ### Enter your vCenter Server
    vCenterUser            ### Enter your vCenter Administrator Account
    vCenterPassword        ### Enter your vCenter Administrator Password
    BaseVM                 ### Enter the name of the machine you want to clone
    TargetVMs              ### Enter the name of the clone, you can enter multiple targets for more clones like : "Fileserver01-Test","Fileserver02-Test"
    ResourcePool           ### Enter the name of your resource pool, you can leave this empty if you use the VMhost parameter
    TargetDatastore        ### Enter the name of the datastore on which the clone will be stored
    VMHost                 ### Enter the VMHost, you can leave this empty if you use ResourcePool
   
.EXAMPLE
    New-VMLinkedClone -vCenterserver "itgaiden.pokemon.jp" -vCenterUser "administrator@vsphere.local" -vCenterPassword "VMware1!" -BaseVM "testclonevRI" -TargetVMs "FILESERVER01-ACC","FILTERSER01-TEST" -TargetDatastore "QNAP_Datastore" -VMHost "192.168.1.201"
    
    This will create a snapshot named 'Linked-Snapshot-for-FILESERVER01-ACC FILTERSER01-TEST' on the VM FILESERVER01. From this snapshot there will be two VM's created called FILESERVER01-ACC FILTERSER01-TEST on ESXI host ESXI01 on Datastore VMware01. 
 
.EXAMPLE
    New-VMLinkedClone -vCenterserver "vcenter.domain.com" -vCenterUser "administrator@vsphere.local" -vCenterPassword "P@ssw0rd" -BaseVM "SERVER01" -TargetVMs "SERVER02" -TargetDatastore "SSD" -ResourcePool "Production" 
    
    This will create a snapshot named 'Linked-Snapshot-for-SERVER02' on the VM SERVER01. From this snapshot there will be a VM created called SERVER02 in ResourcePool Production on Datastore SSD. 
 
#>
 Function New-VMLinkedClone {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)]
        [string]$vCenterserver,
        [array] $TargetVMs,
        [string]$vCenterUser,
        [String]$vCenterPassword,
        [string]$BaseVM,
        [string]$TargetDatastore,
        [Parameter(Mandatory = $false)]
        [string]$ResourcePool,
        [string]$VMHost
    )
 
    #### Load in PowerCLI
    # Returns the path (with trailing backslash) to the directory where PowerCLI is installed.
    if ( !(Get-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) ) {
        if (Test-Path -Path 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\VMware, Inc.\VMware vSphere PowerCLI' ) {
            $Regkey = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\VMware, Inc.\VMware vSphere PowerCLI'
       
        }
        else {
            $Regkey = 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\VMware, Inc.\VMware vSphere PowerCLI'
        }
        . (join-path -path (Get-ItemProperty  $Regkey).InstallPath -childpath 'Scripts\Initialize-PowerCLIEnvironment.ps1')
    }
    if ( !(Get-Module -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) ) {
        Write-Host "VMware modules not loaded/unable to load"
    }

    ### Connect vSphere
    Connect-VIServer -server $vCenterserver -user $vCenterUser -Password $vCenterPassword

    ### Check if there is already a linkedclone snapshot for the clone and delete it
    $SnapshotExists = Get-Snapshot -VM $BaseVM

    if ($SnapshotExists.Name -eq "Linked-Snapshot-for-$TargetVMs") {
        Write-Host "Linked-Snapshot-for-$TargetVMs already exists" -ForegroundColor red 
        Read-Host -Prompt "Press any key to delete the snapshot and continue or CTRL+C to quit" 

        $ExistingSnapshot = Get-Snapshot -VM $BaseVM -Name "Linked-Snapshot-for-$TargetVMs"
        Remove-Snapshot -Snapshot $ExistingSnapshot -Confirm:$false
        write-host "Old snapshot deleted" -ForegroundColor Green
    }

    ### Create Master Snapshot
    $SnapShot = New-Snapshot -VM $BaseVM -Name "Linked-Snapshot-for-$TargetVMs" -Description "Snapshot for linked clones for $TargetVM" -Memory -Quiesce
    Write-Host "Snapshot create on $BaseVM" -ForegroundColor Green

    ### Create Linked Clones
    ForEach ($TargetVM in $TargetVMs) {
        if ($ResourcePool) {
            $LinkedClone = New-VM -Name $TargetVM -VM $BaseVM -Datastore $TargetDatastore -ResourcePool $ResourcePool -LinkedClone -ReferenceSnapshot $SnapShot
            write-host "Linked clone $TargetVM created" -ForegroundColor Green
        }
        if ($VMHost) {
            $LinkedClone = New-VM -Name $TargetVM -VM $BaseVM -Datastore $TargetDatastore -VMHost $VMhost -LinkedClone -ReferenceSnapshot $SnapShot
            write-host "Linked clone $TargetVM created" -ForegroundColor Green
        }
    }
}