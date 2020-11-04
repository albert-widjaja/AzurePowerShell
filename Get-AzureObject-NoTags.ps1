<#
.DESCRIPTION: Get all Azure resources without Tags
#>

Clear-Host

#Start Time
$startTime = "{0:G}" -f (Get-Date)
Write-Host "*** Script started on $startTime ***`n`n" -ForegroundColor White -BackgroundColor Blue
Write-Host "Script executed under $((Get-AzContext).Account.Id)" -ForegroundColor Cyan
$AZSubscriptions = Get-AzSubscription

ForEach ($AZSubscription in $AZSubscriptions) {
    Write-Host "Selecting Azure Subscription [$($AZSubscription.Name)] - $($AZSubscription.Id)" -ForegroundColor Yellow
    Select-AzSubscription -SubscriptionId $AZSubscription.Id
    $resources = Get-AzResource

    & {
        foreach ($resource in $resources) {
            if ($null -eq $resource.Tags) {
                [PSCustomObject]@{
                    Name              = $resource.Name
                    ResourceType      = $resource.ResourceType
                    ResourceGroupname = $resource.ResourceGroupName
                    ResourceLocation  = $resource.Location
                }
            }
        }
    } | Out-GridView -Title "Azure objects with no tags under [$((Get-AzContext).Subscription.Name) - $((Get-AzContext).Subscription.Id)] as at $((Get-Date).ToString('dddd dd/MM/yyyy HH:mm tt [UTC K]'))"
}

#End Time
$endTime = "{0:G}" -f (Get-Date)
Write-Host "`n`n*** Script finished on $endTime ***" -ForegroundColor White -BackgroundColor Blue
Write-Host "Time elapsed: $(New-Timespan $startTime $endTime)" -ForegroundColor White -BackgroundColor DarkRed
