#!/bin/bash

# Variables
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

echo "Redeploying application with connection string fix..."

# Create deployment package (without web.config - Azure handles Node.js apps automatically)
echo "Creating deployment package..."
if command -v zip &> /dev/null; then
    if [ -f .deployment ]; then
        zip -r deployment.zip server.js package.json public/ .deployment -x "*.git*" "node_modules/*"
    else
        zip -r deployment.zip server.js package.json public/ -x "*.git*" "node_modules/*"
    fi
else
    echo "zip command not found, using PowerShell instead..."
    if [ -f .deployment ]; then
        powershell -Command "Compress-Archive -Path server.js,package.json,public/*,.deployment -DestinationPath deployment.zip -Force"
    else
        powershell -Command "Compress-Archive -Path server.js,package.json,public/* -DestinationPath deployment.zip -Force"
    fi
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
