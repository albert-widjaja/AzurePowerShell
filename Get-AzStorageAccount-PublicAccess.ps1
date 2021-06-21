<#
.DESCRIPTION
    Get Azure Storage Account with PublicAccess that is not explicitly set to Off
.LINK
    https://docs.microsoft.com/en-us/azure/storage/blobs/anonymous-read-access-configure?tabs=portal
    https://docs.microsoft.com/en-us/powershell/module/az.storage/get-azstorageaccount?view=azps-6.1.0
    https://docs.microsoft.com/en-us/powershell/module/az.storage/get-azstoragecontainer?view=azps-6.1.0
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

    $AllStorageAccounts = Get-AzStorageAccount
    $timeZone = Get-TimeZone
    $ResultFile = "$ENV:USERPROFILE\Desktop\Result-AzStorageAccount-$((Get-AzContext).Subscription.Name)-$(Get-Date -f 'dd-MM-yyyy').CSV"

    $AllStorageAccounts | ForEach-Object {
	    $azStorageAccount = $_
	    $storageAccount = Get-AzStorageAccount -ResourceGroupName $azStorageAccount.ResourceGroupName -Name $azStorageAccount.StorageAccountName

        Write-Host " Processing Resource Group: [$($storageAccount.ResourceGroupName)] Storage Account : [$($storageAccount.StorageAccountName)] ..." -ForegroundColor Yellow

	    Get-AzStorageContainer -Context $storageAccount.Context |
		    Where-Object {$_.PublicAccess -ne 'Off'} |
		    Select-Object -Property `
			    Name,
			    PublicAccess,
			    LastModified,
			          @{n = 'LastModifiedTime (Local)'; e = { Try { [System.TimeZoneInfo]::ConvertTimeBySystemTimeZoneId( $_.LastModified , $timeZone.Id) } Catch { $_.Exception.Message } } },
			          @{n = 'URI'; e={$_.BlobContainerClient.Uri}},
			          @{n = 'AccountName'; e={$_.BlobContainerClient.AccountName}},
			          @{n = 'Resource Group'; e = {$azStorageAccount.ResourceGroupName}},
			          @{n = 'AllowBlobPublicAccess'; e = {$azStorageAccount.AllowBlobPublicAccess}},
			          @{n = 'EnableHttpsTrafficOnly'; e = { $azStorageAccount.EnableHttpsTrafficOnly}},
                @{n = 'Minimum TLS Version'; e = { $storageAccount.MinimumTlsVersion}},
                @{n = 'Network Rule Set'; e = { "Bypass: $($storageAccount.NetworkRuleSet.Bypass), `nDefaultAction: $($storageAccount.NetworkRuleSet.DefaultAction), `nIP Rules: $($storageAccount.NetworkRuleSet.IpRules), `nVirtualNetworkRules: $($storageAccount.NetworkRuleSet.VirtualNetworkRules | Select-Object -ExpandProperty VirtualNetworkResourceId)"}},
			          @{n = 'Location'; e = {$azStorageAccount.Location }},
			          @{n = 'Storage Account Tags'; e = {$azStorageAccount.Tags.GetEnumerator().ForEach({"$($_.Key): $($_.Value)"}) -join ', '}},
                @{n = 'Resource Group Tags'; e = {(Get-AzResourceGroup -Name $azStorageAccount.ResourceGroupName).Tags.GetEnumerator().ForEach({"$($_.Key): $($_.Value)"}) -join ', '}}

    } | Export-Csv -Path $ResultFile -NoTypeInformation

}
#End Time
$endTime = "{0:G}" -f (Get-Date)
Write-Host "`n`n*** Script finished on $endTime ***" -ForegroundColor White -BackgroundColor Blue
Write-Host "Time elapsed: $(New-Timespan $startTime $endTime)" -ForegroundColor White -BackgroundColor DarkRed
