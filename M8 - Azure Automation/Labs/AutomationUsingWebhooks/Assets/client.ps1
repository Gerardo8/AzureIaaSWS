$uri = "https://s1events.azure-automation.net/webhooks?token=Vd1tcvmsjc3KL6z1kSyVwleiiK2dEm7Jq3zV1TZKkcA%3d"
$headers = @{"From"="user@contoso.com";"Date"="02/23/2016 15:47:00"}

$myvars  = @(
    @{AzureResourceGroup="rgVMs";Shutdown="true" }
)

$body = ConvertTo-Json -InputObject $myvars 

$response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body

Write-Output $response.JobIds 


