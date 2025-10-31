#!/bin/bash

# Variables
# Get the webapp names from the output of azure-infrastructure.sh
echo "Please enter the EastUS Web App name from the infrastructure script output:"
read WEBAPP_EAST

echo "Please enter the CentralUS Web App name from the infrastructure script output:"
read WEBAPP_CENTRAL
RESOURCE_GROUP_EAST="EastUSResourceGroup"
RESOURCE_GROUP_CENTRAL="CentralUSResourceGroup"

# Ensure we have the right dependencies
echo "Installing dependencies..."
npm install

# Create a zip file for deployment
echo "Creating deployment package..."
# Check if zip command exists, if not try powershell
if command -v zip &> /dev/null; then
    zip -r deployment.zip . -x "*.git*" "node_modules/*" "deployment.zip" "azure-infrastructure.sh" "deploy.sh"
else
    # Fallback to PowerShell for Windows environments
    echo "zip command not found, using PowerShell instead..."
    powershell -Command "Compress-Archive -Path *.js,*.json,public/* -DestinationPath deployment.zip -Force"
fi

# Deploy to East US Web App
echo "Deploying to East US Web App..."
az webapp deployment source config-zip --resource-group $RESOURCE_GROUP_EAST --name $WEBAPP_EAST --src deployment.zip

# Deploy to Central US Web App
echo "Deploying to Central US Web App..."
az webapp deployment source config-zip --resource-group $RESOURCE_GROUP_CENTRAL --name $WEBAPP_CENTRAL --src deployment.zip

# Clean up
echo "Cleaning up..."
rm deployment.zip

echo "Deployment completed successfully!"
echo "Your application is now available at:"
echo "East US: https://$WEBAPP_EAST.azurewebsites.net"
echo "Central US: https://$WEBAPP_CENTRAL.azurewebsites.net"
echo "Traffic Manager: https://<your-traffic-manager-dns>.trafficmanager.net"
