#===============================================================================
# Microsoft FastTrack for Azure
# Validate and export Logic Apps in an Integration Service Environment
# Based on https://github.com/wsilveiranz/iseexportutilities by Wagner Silveira
#===============================================================================
# Copyright © Microsoft Corporation.  All rights reserved.
# THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY
# OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT
# LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE.
#===============================================================================
param(
    [Parameter(Mandatory)]$subscriptionId,
    [Parameter(Mandatory)]$region,
    [Parameter(Mandatory)]$resourceGroupName,
    [Parameter(Mandatory)]$iseName
)
# Login to Azure
Connect-AzAccount

# Set subscription context
Set-AzContext -Subscription $subscriptionId

# Get access token for the ARM management endpoint
$accessToken = Get-AzAccessToken

# Create Authorization header for the HTTP requests
$authHeader = "Bearer " + $accessToken.Token
$head = @{"Authorization"=$authHeader}

# Define the validation endpoint URL and export endpoint URL
$validateUrl = 'https://management.azure.com/subscriptions/' + $subscriptionId + '/providers/Microsoft.Logic/locations/' + $region + '/ValidateWorkflowExport?api-version=2022-09-01-preview'
$exportUrl = 'https://management.azure.com/subscriptions/' + $subscriptionId + '/providers/Microsoft.Logic/locations/' + $region + '/WorkflowExport?api-version=2022-09-01-preview'

# Get all the Logic Apps for specified ISE
$logicApps = @()
Get-AzResource -ResourceGroupName $resourceGroupName -ResourceType 'Microsoft.Logic/workflows' -ExpandProperties | ForEach-Object {
    $itemproperties = $_ | Select-Object Name -ExpandProperty Properties
    # Check if the Logic App is using an ISE
    if([bool]$itemproperties.PSObject.Properties['integrationServiceEnvironment'])
    {
        $ise = $itemproperties | Select-Object -ExpandProperty integrationServiceEnvironment
        # Check if the ISE is the one we are looking for
        if ($ise.name -eq $isename)
        {
            # Add the Logic App to the result
            $logicApps += $_.ResourceId
        }
    }
}

# Validate and Export each Logic App from the specified ISE
$logicApps | ForEach-Object {
    $body = '{"properties":{"workflows":[{"id":"' + $_ + '"}],"workflowExportOptions":""}}'
    $validateResponse = Invoke-WebRequest -UseBasicParsing $validateUrl -Headers $head -ContentType 'application/json' -Method POST -Body $body
    if ($validateResponse.StatusCode -eq '200') {
        $validateResponseContent = ConvertFrom-Json -InputObject $validateResponse.Content
        Write-Host $validateResponseContent.properties.workflows.PSObject.Properties.Name 'Validated successfully' -ForegroundColor Green
        Write-Host 'Details'
        Write-Host '======='
        $validateResponseContent.properties.workflows.PSObject.Properties.Value | ConvertTo-Json
        $exportResponse = Invoke-WebRequest -UseBasicParsing $exportUrl -Headers $head -ContentType 'application/json' -Method POST -Body $body
        if ($exportResponse.StatusCode -eq '200') {
            $exportResponseContent = ConvertFrom-Json -InputObject $exportResponse.Content
            Write-Host $validateResponseContent.properties.workflows.PSObject.Properties.Name 'Exported successfully' -ForegroundColor Green
            Write-Host 'Details'
            Write-Host '======='
            Write-Host 'Package Link:' $exportResponseContent.properties.packageLink.uri
            Write-Host
            $exportResponseContent.properties.details | ForEach-Object {
                Write-Host $_.exportDetailCategory $_.exportDetailCode $_.exportDetailMessage -ForegroundColor Yellow
            }
            Write-Host
        }
        else {
            Write-Host $_ 'Export failed' -ForegroundColor Red
            Write-Host 'Details'
            Write-Host '======='
            Write-Host 'Status Code:' $exportResponse.StatusCode
            Write-Host 'Content:' $exportResponse.Content
            Write-Host
        }
    }
    else {
        Write-Host $_ 'Validation failed' -ForegroundColor Red
        Write-Host 'Details'
        Write-Host '======='
        Write-Host 'Status Code:' $validateResponse.StatusCode
        Write-Host 'Content:' $validateResponse.Content
        Write-Host
    }
}