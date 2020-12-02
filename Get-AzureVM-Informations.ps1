<#
.DESCRIPTION: Match Azure Virtual Machine name with Computer name in guest OS and gather some additonal VM informations.
#>

$AZSubscriptions = Get-AzSubscription | Out-GridView -Title "Script executed under [$((Get-AzContext).Account.Id)], Please select Azure subscription to scan (Hold on Ctrl to select multiple)" -OutputMode 'Multiple'

if ($AZSubscriptions) {
    ForEach ($AZSubscription in $AZSubscriptions) {
        Write-Host "Selecting Azure Subscription [$($AZSubscription.Name)] - $($AZSubscription.Id)" -ForegroundColor Yellow
		
        # Get all the subscriptions
        $Contexts = Select-AzSubscription -SubscriptionId $AZSubscription.Id -Verbose
        $publicIps = Get-AzPublicIpAddress
		
        # Get all the VMs along with subscription name
        $VMs = $Contexts | ForEach-Object {
			
            foreach ($azVM in Get-AzVM) {
                foreach ($publicIp in $publicIps) {
                    if ((Get-AzNetworkInterface -Name $networkProfile).IpConfigurations.id -eq $publicIp.ipconfiguration.Id) {
                        $azVMPublicIPAddress = $publicIp.ipaddress
                    }
                }
				
                $networkProfile = $azVm.NetworkProfile.NetworkInterfaces.id.Split("/") | Select-Object -Last 1
                $vmName = $azVm.OsProfile.ComputerName
                $rgName = $azVm.ResourceGroupName
                $hostname = (Get-AzVM -ResourceGroupName $rgName -Name $vmName -Status).ComputerName
                $powerState = (Get-AzVM -ResourceGroupName $rgName -Name $vmName -Status).Statuses.DisplayStatus[1]
                $azVMSize = (Get-AzVM -ResourceGroupName $rgName -Name $vmName).HardwareProfile.VmSize
                $IPConfig = (Get-AzNetworkInterface -Name $networkProfile).IpConfigurations.PrivateIpAddress
                $azVMSubnet = (Get-AzNetworkInterface -Name $networkProfile).IpConfigurations.subnet.Id.Split("/")[-1]

                Write-Host " Processing Subscription: [$($Contexts.Subscription.Name)] - Resource Group: [$($rgName)] - VM: [$($vmName)] " -ForegroundColor Yellow
                
                [pscustomobject]@{
                    "Resource Group Name"     = $azVM.ResourceGroupName
                    "VM Location"             = $azVM.Location
                    "VM Provisioning Status"  = $azVM.ProvisioningState
                    "Power State"             = $powerState
                    "VM Size"                 = $azVMSize
                    Name                      = $vmName
                    "OS Name"                 = $azvm.StorageProfile.OsDisk.OsType
                    ComputerName              = $hostname
                    "VNET"                    = $azVMSubnet
                    "Local IP Addresses"      = $IPConfig
                    "Public IP Address"       = $azVMPublicIPAddress
                    "VM Local Admin"          = $azvm.OSProfile.AdminUsername
                    Tags                      = $azVM.Tags
                    "Az Name Match Host Name" = $azVm.OsProfile.ComputerName.equals($hostname)
                    "VM Zone"                 = $azVM.Zones
                }
            }
        }
		
        # Get the list of ports exposed to internet
        $VMs | Out-GridView -Title "Azure VMs under [$((Get-AzContext).Subscription.Name) - $((Get-AzContext).Subscription.Id)] as at $((Get-Date).ToString('dddd dd/MM/yyyy HH:mm tt ')) $([System.TimeZoneInfo]::FindSystemTimeZoneById((Get-WmiObject win32_timezone).StandardName))"
    }
}
