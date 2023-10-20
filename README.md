# ise-migration
Contains helpful tools and scripts for migrating your ISE to Logic Apps Standard

## bulk-migration
This folder contains a PowerShell script that will perform a validation and export on every Logic App within an Integration Service Environment. Adapted from Wagner Silveira's [ise export utilities](https://github.com/wsilveiranz/iseexportutilities).

## Pre-requisites
### bulk-migration/Validate-And-Export-ISE-LogicApps.ps1
- The user or service principal used to authenticate must have Contributor access on the resource group containing the Integration Service Environment