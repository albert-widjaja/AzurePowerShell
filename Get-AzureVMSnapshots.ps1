<#
.DESCRIPTION: Get Azure VM Snapshot information from all available Subscriptions
.LINK:
    https://docs.microsoft.com/en-us/powershell/module/az.accounts/get-azsubscription?view=azps-4.8.0
    https://docs.microsoft.com/en-us/powershell/module/az.compute/get-azsnapshot?view=azps-4.8.0
#>

Clear-Host

#Start Time
$startTime = "{0:G}" -f (Get-Date)
Write-Host "*** Script started on $startTime ***`n`n" -ForegroundColor White -BackgroundColor Blue

Write-Host "Script executed under $((Get-AzContext).Account.Id)" -ForegroundColor Cyan

$AZSubscriptions = Get-AzSubscription

ForEach ($AZSubscription in $AZSubscriptions)
{
	Write-Host "Selecting Azure Subscription [$($AZSubscription.Name)] - $($AZSubscription.Id)" -ForegroundColor Yellow
	
	Select-AzSubscription -SubscriptionId $AZSubscription.Id
	
	Get-AzSnapshot | Select-Object @{ n = "Subscription"; e = { $AZSubscription.Name } },
								   ResourceGroupName,
								   Location,
								   Name,
								   DiskSizeGB,
								   OSType,
								   @{ n = "Time Created"; e = { ($_.TimeCreated).ToLocalTime() } },
								   @{ n = 'Snapshot Age'; e = { ([DateTime]::Now - (($_.TimeCreated).ToLocalTime())).ToString("dd' Days 'hh' Hours 'mm' Minutes 'ss' Seconds'") } },
								   @{ n = "SKU Name"; e = { ($_.SKU).Name } },
								   @{ n = "SKU Tier"; e = { ($_.SKU).Tier } },
								   @{ n = "Snapshot Source Subscription \ Resource Group \ Disk"; e = { (($_.CreationData).SourceResourceId | ForEach-Object { "[$((Get-AzSubscription -SubscriptionId $_.Split('/')[2]).Name) \ $($_.Split('/')[-5]) \ $($_.Split('/')[-1])]" }) } },
								   @{ n = "Snapshot Source Object Identifier"; e = { ($_.CreationData).SourceResourceId } } |
	Out-GridView -Title "Azure VM Snapshot under [$((Get-AzContext).Subscription.Name) - $((Get-AzContext).Subscription.Id)] as at $((Get-Date).ToString('dddd dd/MM/yyyy HH:mm tt [UTC K]'))"
}

#End Time
$endTime = "{0:G}" -f (Get-Date)
Write-Host "`n`n*** Script finished on $endTime ***" -ForegroundColor White -BackgroundColor Blue
Write-Host "Time elapsed: $(New-Timespan $startTime $endTime)" -ForegroundColor White -BackgroundColor DarkRed
