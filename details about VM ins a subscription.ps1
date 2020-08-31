<#
    .Author
       Bruno Corsino - bruno.corsino@cloudidentity.pt
       Site: https://corsino.pt


    .SYNOPSIS
        Provide several informations about Virtual Machines
    
#>

#Provide the subscription Id where the VMs reside
$subscriptionId = "SubscriptionID"



Select-AzSubscription $subscriptionId
$report = @()
$vms = Get-AzVM
$publicIps = Get-AzPublicIpAddress 
$nics = Get-AzNetworkInterface | Where-Object { $_.VirtualMachine -NE $null} 
foreach ($nic in $nics) { 
    $info = "" | Select-Object VmName, ResourceGroupName, Region, VirturalNetwork, Subnet, PrivateIpAddress, OsType, Vmsize 
    $vm = $vms | Where-Object -Property Id -eq $nic.VirtualMachine.id 
    foreach($publicIp in $publicIps) { 
        if($nic.IpConfigurations.id -eq $publicIp.ipconfiguration.Id) {
            $info.PublicIPAddress = $publicIp.ipaddress
            } 
        } 
        $info.OsType = $vm.StorageProfile.OsDisk.OsType 
        $info.VmSize = $vm.HardwareProfile.VmSize
        $info.VMName = $vm.Name 
        $info.ResourceGroupName = $vm.ResourceGroupName 
        $info.Region = $vm.Location 
        $info.VirturalNetwork = $nic.IpConfigurations.subnet.Id.Split("/")[-3] 
        $info.Subnet = $nic.IpConfigurations.subnet.Id.Split("/")[-1] 
        $info.PrivateIpAddress = $nic.IpConfigurations.PrivateIpAddress 
        $report+=$info 
    } 
$report | Format-Table VmName, ResourceGroupName, Region, VirturalNetwork, Subnet, PrivateIpAddress, OsType, VMsize 
