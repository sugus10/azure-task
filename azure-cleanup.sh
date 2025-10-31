#!/bin/bash

# This script will clean up all Azure resources created by the azure-setup.sh script

echo "Starting Azure resource cleanup..."

# Get list of resource groups that might have been created
echo "Checking for resource groups..."
EAST_RG=$(az group list --query "[?name=='EastUSResourceGroup'].name" -o tsv)
CENTRAL_RG=$(az group list --query "[?name=='CentralUSResourceGroup'].name" -o tsv)
WEST_RG=$(az group list --query "[?name=='WestUSResourceGroup'].name" -o tsv)

# List all resources before deletion
echo "Listing all resources before deletion..."

if [ ! -z "$EAST_RG" ]; then
  echo "Resources in EastUSResourceGroup:"
  az resource list --resource-group EastUSResourceGroup --output table
fi

if [ ! -z "$CENTRAL_RG" ]; then
  echo "Resources in CentralUSResourceGroup:"
  az resource list --resource-group CentralUSResourceGroup --output table
fi

if [ ! -z "$WEST_RG" ]; then
  echo "Resources in WestUSResourceGroup:"
  az resource list --resource-group WestUSResourceGroup --output table
fi

# Confirm deletion
echo ""
echo "WARNING: This script will delete ALL resources in the following resource groups:"
echo "- EastUSResourceGroup (if exists)"
echo "- CentralUSResourceGroup (if exists)"
echo "- WestUSResourceGroup (if exists)"
echo ""
read -p "Are you sure you want to continue? (y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cleanup cancelled."
  exit 1
fi

# Delete resource groups
echo "Deleting resource groups..."

if [ ! -z "$EAST_RG" ]; then
  echo "Deleting EastUSResourceGroup..."
  az group delete --name EastUSResourceGroup --yes --no-wait
  echo "Deletion initiated for EastUSResourceGroup."
fi

if [ ! -z "$CENTRAL_RG" ]; then
  echo "Deleting CentralUSResourceGroup..."
  az group delete --name CentralUSResourceGroup --yes --no-wait
  echo "Deletion initiated for CentralUSResourceGroup."
fi

if [ ! -z "$WEST_RG" ]; then
  echo "Deleting WestUSResourceGroup..."
  az group delete --name WestUSResourceGroup --yes --no-wait
  echo "Deletion initiated for WestUSResourceGroup."
fi

echo ""
echo "Resource deletion has been initiated. This process may take several minutes to complete."
echo "You can check the status in the Azure Portal or using the following command:"
echo "az group list --query \"[?name=='EastUSResourceGroup' || name=='CentralUSResourceGroup' || name=='WestUSResourceGroup']\" -o table"
echo ""
echo "After cleanup is complete, you can run the azure-setup.sh script to deploy fresh resources."
