#!/bin/bash

RESOURCE_GROUP_EAST="EastUSResourceGroup"
RESOURCE_GROUP_CENTRAL="CentralUSResourceGroup"

# Auto-detect web app names
echo "Detecting web app names..."
WEBAPP_EAST=$(az webapp list --resource-group $RESOURCE_GROUP_EAST --query "[0].name" -o tsv)
WEBAPP_CENTRAL=$(az webapp list --resource-group $RESOURCE_GROUP_CENTRAL --query "[0].name" -o tsv)

if [ -z "$WEBAPP_EAST" ] || [ -z "$WEBAPP_CENTRAL" ]; then
    echo "Error: Could not detect web app names. Please check resource groups."
    exit 1
fi

echo "Found Web Apps:"
echo "  East US: $WEBAPP_EAST"
echo "  Central US: $WEBAPP_CENTRAL"
echo ""

echo "Fixing deployment configuration..."

# Set startup command to ensure npm install runs
echo "1. Setting startup command..."
az webapp config set --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST \
  --startup-file "npm start"

az webapp config set --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL \
  --startup-file "npm start"

# Enable SCM_DO_BUILD_DURING_DEPLOYMENT
echo "2. Enabling build during deployment..."
az webapp config appsettings set --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST \
  --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true

az webapp config appsettings set --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL \
  --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true

echo "3. Deployment configuration updated!"
echo "Now redeploy the application with: ./redeploy.sh"
