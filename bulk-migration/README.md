# Validate-And-Export-ISE-LogicApps.ps1
This script will retrieve all of the Logic Apps within the specified Integration Service Environment. For each Logic App it will run the Validation API to determine if the workflow can be migrated to Logic Apps Standard. If the workflow passes validation, the script will call the Export API to create an export package containing the source code for deployment to Logic Apps Standard. Results of the validation and export are displayed for each Logic App.


## Inputs
- subscriptionId - The Azure subscription ID
- region - Azure region
- resourceGroupName - Resource Group Name of the resource group that contains the Integration Service Environment
- iseName - Integration Service Environment name