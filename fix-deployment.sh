#!/bin/bash

WEBAPP_EAST="EastUSWebApp1761914463"
WEBAPP_CENTRAL="CentralUSWebApp1761914463"
RESOURCE_GROUP_EAST="EastUSResourceGroup"
RESOURCE_GROUP_CENTRAL="CentralUSResourceGroup"

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
