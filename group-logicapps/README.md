# LogicApps-By-Connection.ps1
This script will retrieve all of the Logic Apps within the specified Integration Service Environment. For each Logic App it will retrieve all of the Connectors being used by the Logic App. The list of Logic Apps and their associated Connectors will be exported to a .CSV file. The list can then be sorted in Excel to assist in determining how to group Logic Apps for export and deployment to Logic Apps Standard.


## Inputs
- subscriptionId - The Azure subscription ID
- resourceGroupName - Resource Group Name of the resource group that contains the Integration Service Environment
- iseName - Integration Service Environment name
- outputFilePath - Full file path of the generated .CSV file