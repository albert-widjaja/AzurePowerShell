<#
.DESCRIPTION: Scan all the Network Security Groups in all the subscriptions and list the internet exposed ports
#>

$AZSubscriptions = Get-AzSubscription | Out-GridView -Title "Script executed under [$((Get-AzContext).Account.Id)] select Azure subscription" -OutputMode 'Multiple'

if ($AZSubscriptions) {

    ForEach ($AZSubscription in $AZSubscriptions) {
        Write-Host "Selecting Azure Subscription [$($AZSubscription.Name)] - $($AZSubscription.Id)" -ForegroundColor Yellow

        # Get all the subscriptions
        $Contexts = Select-AzSubscription -SubscriptionId $AZSubscription.Id -Verbose

        # Get all the NSGs along with subscription name
        $NSGs = $Contexts | ForEach-Object {
            $Subscription = $_
            Get-AzNetworkSecurityGroup -DefaultProfile $Subscription | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name SubscriptionName -Value $Subscription.Subscription.Name; $_
            }
        }

        # Get the list of ports exposed to internet
        $NSGs | ForEach-Object {
            $NSG = $_
            $_.SecurityRules | ForEach-Object {
                $Port = $_ | ForEach-Object DestinationPortRange
                if ($Port -in (3389, 22, 80, 443, 1433)) {
                    [PSCustomObject]@{
                        SubscriptionName  = $NSG.SubscriptionName
                        ResourceGroupName = $NSG.ResourceGroupName
                        "NSG Name"        = $NSG.Name
                        SecurityRuleName  = $_.Name
                        Access            = $_.Access
                        Port              = $Port
                    }
                }
            }
        } | Out-GridView -Title "Azure NSG with Open Ports under [$((Get-AzContext).Subscription.Name) - $((Get-AzContext).Subscription.Id)] as at $((Get-Date).ToString('dddd dd/MM/yyyy HH:mm tt [UTC K]'))"
    }
}
