workflow Shutdown-Start-VMs-By-Resource-Group
{
	Param
    (   
		# Using WebhookData allows us to pass in multiple parameters
        [object]$WebhookData
       
    )
	
	# If the webhookdata is null, that probably means the runbook is being executed somehow other than via a webhook
	if ($WebhookData -ne $null)
	{
		$WebhookName    =   $WebhookData.WebhookName
    	$WebhookHeaders =   $WebhookData.RequestHeader
	    $WebhookBody    =   $WebhookData.RequestBody
		
		# Convert the object FROM Json back to a regular paramter
		$myVars = ConvertFrom-Json -InputObject $WebhookBody;
		
		# recover the paramter values
		$AzureResourceGroup = $myVars.AzureResourceGroup
		$Shutdown = $myVars.Shutdown	
	
		if ($AzureResourceGroup -eq $null)
		{
			Throw "Parameter AzureResourceGroup is null"
		}
		
		if ($Shutdown -eq $null)
		{
			$Shutdown = $true
		}
	
		$connectionName = "AzureRunAsConnection"
        try
        {
            # Get the connection "AzureRunAsConnection "
            $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         

            "Logging in to Azure..."
            Add-AzureRmAccount `
                -ServicePrincipal `
                -TenantId $servicePrincipalConnection.TenantId `
                -ApplicationId $servicePrincipalConnection.ApplicationId `
                -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
        }
        catch {
            if (!$servicePrincipalConnection)
            {
                $ErrorMessage = "Connection $connectionName not found."
                throw $ErrorMessage
            } else{
                Write-Error -Message $_.Exception
                throw $_.Exception
            }
        }

		if($Shutdown -eq $true){
			Write-Output "Stopping VMs in '$($AzureResourceGroup)' resource group";
		}
		else{
			Write-Output "Starting VMs in '$($AzureResourceGroup)' resource group";
		}
		
		#ARM VMs
		Write-Output "ARM VMs:";
		  
		Get-AzureRmVM -ResourceGroupName $AzureResourceGroup | ForEach-Object {
		
			if($Shutdown -eq $true){
				
					Write-Output "Stopping '$($_.Name)' ...";
					Stop-AzureRmVM -ResourceGroupName $AzureResourceGroup -Name $_.Name -Force;
			}
			else{
				Write-Output "Starting '$($_.Name)' ...";			
				Start-AzureRmVM -ResourceGroupName $AzureResourceGroup -Name $_.Name;			
			}			
		};
		
		
		
		#ASM VMs
		Write-Output "ASM VMs:";
		
		Get-AzureRmResource | where { $_.ResourceGroupName -match $AzureResourceGroup -and $_.ResourceType -eq "Microsoft.ClassicCompute/VirtualMachines"} | ForEach-Object {
			
			$vmName = $_.Name;
			if($Shutdown -eq $true){
				
				Get-AzureVM | where {$_.Name -eq $vmName} | ForEach-Object {
					Write-Output "The machine '$($_.Name)' is $($_.PowerState)";
					
					if($_.PowerState -eq "Started"){
						Write-Output "Stopping '$($_.Name)' ...";		
						Stop-AzureVM -ServiceName $_.ServiceName -Name $_.Name -Force;
					}
				}
			}
			else{
				
				Get-AzureVM | where {$_.Name -eq $vmName} | ForEach-Object {
					Write-Output "The machine '$($_.Name)' is $($_.PowerState)";
									
					if($_.PowerState -eq "Stopped"){
						Write-Output "Starting '$($_.Name)' ...";		
						Start-AzureVM -ServiceName $_.ServiceName -Name $_.Name;
					}
				}
			}		
		};
	}
	else
	{
		Write-Error "Runbook can only be started from a webhook"
	}
}

