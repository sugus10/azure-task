#!/bin/bash

# Quick fix script for existing deployments
# This fixes common issues that cause 402/502 errors and static website display

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

echo "=== Step 1: Fixing application settings ==="
# Fix application settings - ensure all required settings are present
az webapp config appsettings set --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST \
  --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true WEBSITE_NODE_DEFAULT_VERSION="~16" --output none

az webapp config appsettings set --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL \
  --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true WEBSITE_NODE_DEFAULT_VERSION="~16" --output none

echo "✓ Application settings updated"

echo ""
echo "=== Step 2: Configuring startup command ==="
# Set startup command
az webapp config set --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST \
  --startup-file "npm start" \
  --always-on true

az webapp config set --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL \
  --startup-file "npm start" \
  --always-on true

echo "✓ Startup command configured"

echo ""
echo "=== Step 3: Creating deployment package ==="
# Create deployment package with .deployment file
if command -v zip &> /dev/null; then
    if [ -f .deployment ]; then
        zip -r deployment.zip server.js package.json public/ .deployment -x "*.git*" "node_modules/*" -q
    else
        zip -r deployment.zip server.js package.json public/ -x "*.git*" "node_modules/*" -q
    fi
else
    echo "zip command not found, using PowerShell instead..."
    if [ -f .deployment ]; then
        powershell -Command "Compress-Archive -Path server.js,package.json,public/*,.deployment -DestinationPath deployment.zip -Force"
    else
        powershell -Command "Compress-Archive -Path server.js,package.json,public/* -DestinationPath deployment.zip -Force"
    fi
fi

echo "✓ Deployment package created"

echo ""
echo "=== Step 4: Deploying application ==="
# Deploy to both web apps
az webapp deployment source config-zip --resource-group $RESOURCE_GROUP_EAST --name $WEBAPP_EAST --src deployment.zip
az webapp deployment source config-zip --resource-group $RESOURCE_GROUP_CENTRAL --name $WEBAPP_CENTRAL --src deployment.zip

echo "✓ Application deployed"

echo ""
echo "=== Step 5: Waiting for deployment to process ==="
sleep 15

echo ""
echo "=== Step 6: Restarting web apps ==="
az webapp restart --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST
az webapp restart --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL

echo "✓ Web apps restarted"

echo ""
echo "=========================================="
echo "Fix completed! Waiting 30 seconds for apps to start..."
echo "=========================================="
sleep 30

echo ""
echo "Testing endpoints..."
echo ""
echo "East US Web App:"
echo "  Health check: https://$WEBAPP_EAST.azurewebsites.net/api/health"
echo "  Main app: https://$WEBAPP_EAST.azurewebsites.net"
echo ""
echo "Central US Web App:"
echo "  Health check: https://$WEBAPP_CENTRAL.azurewebsites.net/api/health"
echo "  Main app: https://$WEBAPP_CENTRAL.azurewebsites.net"
echo ""
echo "If you still see issues, check logs with:"
echo "  az webapp log tail --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST"
echo ""

