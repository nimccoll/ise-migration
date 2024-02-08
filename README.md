# ise-migration
Contains helpful tools and scripts for migrating your ISE to Logic Apps Standard

## bulk-migration
This folder contains a PowerShell script that will perform a validation and export on every Logic App within an Integration Service Environment. Adapted from Wagner Silveira's [ise export utilities](https://github.com/wsilveiranz/iseexportutilities).

## group-logicapps
This folder contains a PowerShell script that will list all of the connectors used by each Logic App within an ISE and export the list to a .CSV file. This list can assist a customer in determining how to group Logic Apps when they are exported from an ISE to be deployed to Logic Apps Standard.

## Pre-requisites
### bulk-migration/Validate-And-Export-ISE-LogicApps.ps1
- The user or service principal used to authenticate must have Contributor access on the resource group containing the Integration Service Environment
### group-logicapps/LogicApps-By-Connection.ps1
- The user or service principal used to authenticate must have Reader access on the resource group containing the Integration Service Environment