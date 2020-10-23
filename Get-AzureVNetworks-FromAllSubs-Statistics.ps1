<#
.DESCRIPTION: Reiterates through all Azure Subscriptions and get Azure some VNet properties and then Out-GridView
#>


Clear-Host

#Start Time
$startTime = "{0:G}" -f (Get-Date)
Write-Host "*** Script started on $startTime ***`n`n" -ForegroundColor White -BackgroundColor Blue
Function Extract-String {
    Param(
        [Parameter(Mandatory = $true)][string]$string
        , [Parameter(Mandatory = $true)][char]$character
        , [Parameter(Mandatory = $false)][ValidateSet("Right", "Left")][string]$range
        , [Parameter(Mandatory = $false)][int]$afternumber
        , [Parameter(Mandatory = $false)][int]$tonumber
    )
    Process {
        [string]$return = ""

        if ($range -eq "Right") {
            $return = $string.Split("$character")[($string.Length - $string.Replace("$character", "").Length)]
        }
        elseif ($range -eq "Left") {
            $return = $string.Split("$character")[0]
        }
        elseif ($tonumber -ne 0) {
            for ($i = $afternumber; $i -le ($afternumber + $tonumber); $i++) {
                $return += $string.Split("$character")[$i]
            }
        }
        else {
            $return = $string.Split("$character")[$afternumber]
        }
        return $return
    }
}

Write-Host "Script executed under $((Get-AzContext).Account.Id)" -ForegroundColor Cyan

$AZSubscriptions = Get-AzSubscription

ForEach ($AZSubscription in $AZSubscriptions) {
    Write-Host "Selecting Azure Subscription [$($AZSubscription.Name)] - $($AZSubscription.Id)" -ForegroundColor Yellow

    Select-AzSubscription -SubscriptionId $AZSubscription.Id

    Function Extract-String {
        Param(
            [Parameter(Mandatory = $true)][string]$string
            , [Parameter(Mandatory = $true)][char]$character
            , [Parameter(Mandatory = $false)][ValidateSet("Right", "Left")][string]$range
            , [Parameter(Mandatory = $false)][int]$afternumber
            , [Parameter(Mandatory = $false)][int]$tonumber
        )
        Process {
            [string]$return = ""

            if ($range -eq "Right") {
                $return = $string.Split("$character")[($string.Length - $string.Replace("$character", "").Length)]
            }
            elseif ($range -eq "Left") {
                $return = $string.Split("$character")[0]
            }
            elseif ($tonumber -ne 0) {
                for ($i = $afternumber; $i -le ($afternumber + $tonumber); $i++) {
                    $return += $string.Split("$character")[$i]
                }
            }
            else {
                $return = $string.Split("$character")[$afternumber]
            }
            return $return
        }
    }

    $AZVNETs = Get-AzVirtualNetwork

    & {
        ForEach ($VNET in $AZVNETs) {

            #Get All Subnets in this VNET
            $AZSubnets = Get-AzVirtualNetwork -Name $VNET.Name | Get-AzVirtualNetworkSubnetConfig
            ForEach ($Subnet in $AZSubnets) {

                #Used for counting later
                $SubnetConfigured = $Subnet | Select-Object -ExpandProperty IpConfigurations
                #Gets the mask from the IP configuration (I.e 10.0.0.0/24, turns to just "24")
                $Mask = $Subnet.AddressPrefix
                $Mask = $Mask.substring($Mask.Length - 2, 2)

                #Depends on the mask, sets how many available IP's we have - Add more if required
                switch ($Mask) {
                    '29' { $AvailableAddresses = "3" }
                    '28' { $AvailableAddresses = "11" }
                    '27' { $AvailableAddresses = "27" }
                    '26' { $AvailableAddresses = "59" }
                    '25' { $AvailableAddresses = "123" }
                    '24' { $AvailableAddresses = "251" }
                    '23' { $AvailableAddresses = "507" }
                }

                #Creates a simple table with the VNET Name, Subnet Name, AddressPrefix, IpsConfigured and IpsLeft
                $TableProperties = @(
                    @{Name = "Resource Group Name" ; Expression = { $VNET.ResourceGroupName } }
                    @{Name = "VNET Name" ; Expression = { $VNET.Name } }
                    "Name"
                    @{Name = "AddressSpace"; Expression = { ($VNET.AddressSpace).AddressPrefixes -join ', ' } }
                    @{Name = "Subnets"; Expression = { ($VNET.Subnets).AddressPrefix -join ', ' } }
                    @{Name = "IPsConfigured" ; Expression = { $SubnetConfigured.Count } }
                    @{Name = "IPsLeft" ; Expression = { $AvailableAddresses - $SubnetConfigured.Count } }
                    @{Name = "VNet Peering Name - State" ; Expression = { ($VNET.VirtualNetworkPeerings | ForEach-Object { "[$(($_).Name) - $($_.PeeringState)]" }) -join ', ' } }
                    @{Name = "VNet Peering Remote VNet With Subscription" ; Expression = { ($VNET.VirtualNetworkPeerings | ForEach-Object { "[$((Get-AzSubscription -SubscriptionId (Extract-String -string ($_).RemoteVirtualNetwork.Id -character / -afternumber 2)).Name) \ $((Extract-String -string ($_).RemoteVirtualNetwork.Id -character / -afternumber 4)) \ $(Extract-String -string ($VNET.VirtualNetworkPeerings).RemoteVirtualNetwork.Id -character / -range Right)]" }) -join ', ' } }
                    @{Name = "DDOS Protection" ; Expression = { $VNET.EnableDdosProtection } }
                    @{Name = "DDOS Protection Plan" ; Expression = { $VNET.DdosProtectionPlan } }
                    @{Name = "Location" ; Expression = { $VNET.Location } }
                    @{Name = "Tags Table" ; Expression = { $VNET.TagsTable -join ', ' } }
                )

                $Subnet | Select-Object $TableProperties
            }
        }
    } | Out-GridView -Title "Azure VM Subnet reports under [$((Get-AzContext).Subscription.Name) - $((Get-AzContext).Subscription.Id)] as at $((Get-Date).ToString('dddd dd/MM/yyyy HH:mm tt [UTC K]'))"

}

#End Time
$endTime = "{0:G}" -f (Get-Date)
Write-Host "`n`n*** Script finished on $endTime ***" -ForegroundColor White -BackgroundColor Blue
Write-Host "Time elapsed: $(New-Timespan $startTime $endTime)" -ForegroundColor White -BackgroundColor DarkRed
