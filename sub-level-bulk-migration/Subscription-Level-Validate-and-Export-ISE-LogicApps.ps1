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

# Import the AzureRM module if not already imported
# Import-Module AzureRM

# Parameters
Param (
    [Parameter(Mandatory = $true)]
    [string]$subscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$region,

    [Parameter(Mandatory = $false)]
    [string]$outputCsvPath = "ExportedLogicApps_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".csv"
)

# Login to Azure
Connect-AzAccount

# Set subscription context
Set-AzContext -Subscription $subscriptionId

# Get access token for the ARM management endpoint
$accessToken = Get-AzAccessToken

# Create Authorization header for the HTTP requests
$authHeader = "Bearer " + $accessToken.Token
$head = @{ "Authorization" = $authHeader }

# Define the validation endpoint URL and export endpoint URL
$validateUrl = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Logic/locations/$region/ValidateWorkflowExport?api-version=2022-09-01-preview"
$exportUrl = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Logic/locations/$region/WorkflowExport?api-version=2022-09-01-preview"

# Initialize an array to store Logic App details
$logicAppDetails = @()

# Get all resource groups in the subscription
$resourceGroups = Get-AzResourceGroup

# Iterate through each resource group
foreach ($resourceGroup in $resourceGroups) {
    $resourceGroupName = $resourceGroup.ResourceGroupName

    Get-AzResource -ResourceGroupName $resourceGroupName -ResourceType 'Microsoft.Logic/workflows' -ExpandProperties | ForEach-Object {
        $itemProperties = $_ | Select-Object Name -ExpandProperty Properties
        if ([bool]$itemProperties.PSObject.Properties['integrationServiceEnvironment']) {
            $logicAppDetail = [PSCustomObject]@{
                ResourceGroupName = $resourceGroupName
                LogicAppResourceId = $_.ResourceId
                ExportStatus = "Not Processed"  # Placeholder
                PackageLink = "Not Available"   # Placeholder
            }
            $logicAppDetails += $logicAppDetail
        }
    }
}

# Validate and Export each Logic App
$validateSucceededCount = 0
$validateFailedCount = 0
$validateFailed = @()
$exportSucceededCount = 0
$exportFailedCount = 0
$exportFailed = @()

foreach ($logicAppDetail in $logicAppDetails) {
    $currentLogicApp = $logicAppDetail.LogicAppResourceId
    $resourceGroupName = $logicAppDetail.ResourceGroupName
    $body = '{"properties":{"workflows":[{"id":"' + $currentLogicApp + '"}],"workflowExportOptions":""}}'

    try {
        $validateResponse = Invoke-WebRequest -UseBasicParsing $validateUrl -Headers $head -ContentType 'application/json' -Method POST -Body $body
        if ($validateResponse.StatusCode -eq '200') {
            $validateSucceededCount++
            $validateResponseContent = ConvertFrom-Json -InputObject $validateResponse.Content

            $exportResponse = Invoke-WebRequest -UseBasicParsing $exportUrl -Headers $head -ContentType 'application/json' -Method POST -Body $body
            if ($exportResponse.StatusCode -eq '200') {
                $exportSucceededCount++
                $exportResponseContent = ConvertFrom-Json -InputObject $exportResponse.Content

                # Update the export result object with additional details
                $logicAppDetail.ExportStatus = "Success"
                $logicAppDetail.PackageLink = $exportResponseContent.properties.packageLink.uri
            } else {
                $exportFailedCount++
                $exportFailed += $currentLogicApp
                $logicAppDetail.ExportStatus = "Failed"
                $logicAppDetail.PackageLink = "Not Available"
                $logicAppDetail.ExportDetails = "Status Code: $($exportResponse.StatusCode), Content: $($exportResponse.Content)"
            }
        } else {
            $validateFailedCount++
            $validateFailed += $currentLogicApp
            $logicAppDetail.ExportStatus = "Validation Failed"
            $logicAppDetail.PackageLink = "Not Available"
            $logicAppDetail.ValidationDetails = "Status Code: $($validateResponse.StatusCode), Content: $($validateResponse.Content)"
        }
    } catch {
        $validateFailedCount++
        $validateFailed += $currentLogicApp
        $logicAppDetail.ExportStatus = "Validation Failed"
        $logicAppDetail.PackageLink = "Not Available"
        $logicAppDetail.ValidationDetails = $_.Exception.Message
    }
}

# Output results to CSV
$logicAppDetails | Export-Csv -Path $outputCsvPath -NoTypeInformation

Write-Host "Logic Apps successfully validated: $validateSucceededCount" -ForegroundColor Green
Write-Host "Logic Apps that failed validation: $validateFailedCount" -ForegroundColor Red
Write-Host "Logic Apps successfully exported: $exportSucceededCount" -ForegroundColor Green
Write-Host "Logic Apps that failed export: $exportFailedCount" -ForegroundColor Red

if ($validateFailedCount -gt 0) {
    Write-Host "Logic Apps that failed validation"
    Write-Host "================================="
    $validateFailed | ForEach-Object {
        Write-Host $_
    }
}

if ($exportFailedCount -gt 0) {
    Write-Host "Logic Apps that failed export"
    Write-Host "============================="
    $exportFailed | ForEach-Object {
        Write-Host $_
    }
}
