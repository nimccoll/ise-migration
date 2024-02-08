#===============================================================================
# Microsoft FastTrack for Azure
# List Connectors being used by the Logic Apps in an ISE
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
    [Parameter(Mandatory)]$resourceGroupName,
    [Parameter(Mandatory)]$iseName,
    [Parameter(Mandatory)]$outputFilePath
)
# Login to Azure
Connect-AzAccount

# Set subscription context
Set-AzContext -Subscription $subscriptionId

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
            $resourceName = $_.Name    
            $resourceGroupName = $_.ResourceGroupName
            $resourceGroupPath = '/subscriptions/' + $subscriptionId + '/resourceGroups/' + $resourceGroupName

            $logicApp = Get-AzLogicApp -Name $resourceName -ResourceGroupName $resourceGroupName        
            $logicAppUrl = $resourceGroupPath + '/providers/Microsoft.Logic/workflows/' + $logicApp.Name + '?api-version=2019-05-01'
        
            # Get Logic App Content
            $logicAppJson = az rest --method get --uri $logicAppUrl
            $logicAppJsonText = $logicAppJson | ConvertFrom-Json    

            # Check Logic App Connectors
            $logicAppParameters = $logicAppJsonText.properties.parameters
            $logicAppConnections = $logicAppParameters.psobject.properties.Where({$_.name -eq '$connections'}).value
            $logicAppConnectionValue = $logicAppConnections.value
            $logicAppConnectionValues = $logicAppConnectionValue.psobject.properties.name
    
            Write-Host "`t Resource Group: " -NoNewline; Write-Host $resourceGroupName -ForegroundColor Green -NoNewline; Write-Host "`t -> `t Logic App: " -NoNewline; Write-Host $resourceName -ForegroundColor Green;

            # Iterate through the connectors
            $logicAppConnectionValue.psobject.properties | ForEach-Object {
                $objectName = $_
                $connection = $objectName.Value             
                
                if($connection -ne $null)
                {
                    Write-Host "`t `t Uses API Connection: " -NoNewline; Write-Host $connection.connectionName -ForegroundColor Yellow;  
                    
                    $connectorIdLower = $connection.connectionId.ToLower()
                    $logicApps += New-Object -TypeName PSObject -Property @{
                        ResourceGroupName = $resourceGroupName
                        ISEName = $ise.name
                        LogicAppName = $resourceName
                        ConnectorName = $connection.connectionName
                        ConnectorId = $connectorIdLower
                    }
                }                                            
            }       
        }
    }
}
# Write output to CSV file
if ($logicApps.Count -gt 0) {
    $logicApps | Select-Object -Property ResourceGroupName, ISEName, LogicAppName, ConnectorName, ConnectorId | Export-Csv -Path $outputFilePath -NoTypeInformation
}