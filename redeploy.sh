#!/bin/bash

# Variables
WEBAPP_EAST="EastUSWebApp1761914463"
WEBAPP_CENTRAL="CentralUSWebApp1761914463"
RESOURCE_GROUP_EAST="EastUSResourceGroup"
RESOURCE_GROUP_CENTRAL="CentralUSResourceGroup"

echo "Redeploying application with connection string fix..."

# Create deployment package
echo "Creating deployment package..."
if command -v zip &> /dev/null; then
    zip -r deployment.zip server.js package.json public/
else
    echo "zip command not found, using PowerShell instead..."
    powershell -Command "Compress-Archive -Path server.js,package.json,public/* -DestinationPath deployment.zip -Force"
fi

# Deploy to both web apps
echo "Deploying to East US Web App..."
az webapp deployment source config-zip --resource-group $RESOURCE_GROUP_EAST --name $WEBAPP_EAST --src deployment.zip

echo "Deploying to Central US Web App..."
az webapp deployment source config-zip --resource-group $RESOURCE_GROUP_CENTRAL --name $WEBAPP_CENTRAL --src deployment.zip

# Restart web apps to ensure they pick up changes
echo "Restarting web apps..."
az webapp restart --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST
az webapp restart --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL

echo ""
echo "Deployment completed! Wait about 30 seconds and then check:"
echo "https://$WEBAPP_EAST.azurewebsites.net"
echo ""
echo "To check logs if there are still issues:"
echo "az webapp log tail --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST"
