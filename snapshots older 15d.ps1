<#
    .Author
        Bruno Corsino - bruno.corsino@cloudidentity.pt
    .SYNOPSIS
        Script to remove snapshots older than 15 days.
#>

$ConnectionName = "AzureRunAsConnection"
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection=Get-AutomationConnection -Name $ConnectionName
    "Logging in to Azure..."
    Login-AzAccount -ServicePrincipal -TenantId $servicePrincipalConnection.TenantId `
    -ApplicationId $servicePrincipalConnection.ApplicationId -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 


Get-AzSubscription | Where-Object { $_.State -eq 'Enabled' } | ForEach-Object {
    $sub = Select-AzSubscription $_;
Get-AzSnapshot | select Name, ResourceGroupName, TimeCreated , DiskSizeGB | Where-Object {($_.TimeCreated) -lt ([datetime]::UtcNow.AddDays(-15))} | Remove-AzSnapshot
}