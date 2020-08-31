<#
    .Author
       Bruno Corsino - bruno.corsino@cloudidentity.pt
       Site: https://corsino.pt


    .SYNOPSIS
        For a single Azure VM using managed disks, stops the VM and creates snapshots of all disks, storing them in the same region and resource group as the VM
    
    .EXAMPLE
    New-VMSnapshot -VM [string] -ResourceGroup [string] -ResourceGroupSnapShop [string] -Subscription [string]
    New-NBVMSnapshot -VM 'VM-Name' -ResourceGroup 'RG-Name' -ResourceGroupSnapShop 'Snapshot-RG-Name' -Subscription 'SubscriptionName'
    
    .DESCRIPTION
        Creates snapshots of the a VM's managed disks. There's always only one OsDisk  but there can be multiple data disks in the VM
    
    .PARAMETER VM
        Name of the Virtual Machine
    
    .PARAMETER ResourceGroup
        Resource group where Virtual Machine exists.

    .PARAMETER ResourceGroupSnapShop
        Resource group where the snapShot will be created
    
    .PARAMETER Location
        Region containing all disks: the VM, the volumes and the snapshots
        The default is "North Europe"
    
    .PARAMETER Subscription
        Select the subscription where the virtual machines belongs
    
 

#>


function New-VmSnapshot {
param
(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string]$VM,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string]$ResourceGroup,
    [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
    [string]$ResourceGroupSnapShop,
    [Parameter(Mandatory = $false)]
    [string]$Location = "northeurope",
    [Parameter(Mandatory = $False)]
    [string]$Subscription
)
Select-AzSubscription -Subscription $Subscription

$VmStatus = Get-AzVM -Status -Name $VM -ResourceGroupName $ResourceGroup
foreach ($Status in $VmStatus.Statuses)
{
    if ($Status.Code -eq "PowerState/running")
    {
        Write-Host "VM $VM status: $($Status.Code)" -ForegroundColor Red
        Write-Host "Need to Stop/Deallocate $VM" -ForegroundColor Yellow
        $Continue = Read-Host "Are you sure? Enter yes to continue" 
        if ($Continue.ToLower() -ne 'yes')
        {
            Write-Host "$VM cannot be snapshotted while running" -ForegroundColor Yellow
            "Exiting"
            exit
        }
        "Stopping $VM"
        Stop-AzVM -Name $VM -ResourceGroupName $ResourceGroup -Force | Out-Null
    }
}

$OsDiskName = (Get-AzVM -Name $VM -ResourceGroupName $ResourceGroup).StorageProfile.OSDisk.Name # There is always just one OsDisk
$OsDiskId = (Get-AzDisk -Name $OsDiskName -ResourceGroupName $ResourceGroup).Id
$OsDiskSnapshotConfig = New-AzSnapshotConfig -SourceUri $OsDiskId -Location $Location -CreateOption "Copy"
$SnapshotName = $($OsDiskName + "-" + (Get-Date -Format s).Replace(":", "-"))
If ($SnapshotName.Length -ge 63)
{
    $SnapshotName = $SnapshotName.Substring(0, 63)
}
New-AzSnapshot -Snapshot $OsDiskSnapshotConfig -SnapshotName $SnapshotName -ResourceGroupName $ResourceGroupSnapShop | Out-Null

$DataDisks = (Get-AzVM -Name $VM -ResourceGroupName $ResourceGroup).StorageProfile.DataDisks.Name # There might be a collection of data disks
foreach ($DataDisk in $DataDisks)
{
    $DataDiskID = (Get-AzDisk -Name $DataDisk -ResourceGroupName $ResourceGroup).Id
    $DataDiskSnapshotConfig = New-AzSnapshotConfig -SourceUri $DataDiskID -Location $Location -CreateOption "Copy"
    $SnapshotName = $($DataDisk + "-" + (Get-Date -Format s).Replace(":", "-"))
    If ($SnapshotName.Length -ge 63)
    {
        $SnapshotName = $SnapshotName.Substring(0, 63)
    }
    New-AzSnapshot -Snapshot $DataDiskSnapshotConfig -SnapshotName $SnapshotName -ResourceGroupName $ResourceGroupSnapShop -AsJob | Out-Null
}

"Snapshots for $VM Complete"

        $Continue1 = Read-Host "Enter yes to Start the VM $VM"
        if ($Continue1.ToLower() -ne 'yes')
        {
            Write-Host "$VM will not be started" -ForegroundColor Yellow
            "Exiting"
            exit
        }
      Write-Host "Starting $VM" -ForegroundColor Yellow
      
      Start-AzVM -Name $VM -ResourceGroupName $ResourceGroup | Out-Null

      Write-Host "$VM is running" -ForegroundColor Green
}
