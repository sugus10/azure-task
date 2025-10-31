#!/bin/bash

WEBAPP_EAST="EastUSWebApp1761914463"
RESOURCE_GROUP_EAST="EastUSResourceGroup"

echo "Checking deployment status..."

# Check if web app is running
echo "1. Checking web app status..."
az webapp show --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query "{state:state, defaultHostName:defaultHostName}" -o table

echo ""
echo "2. Checking recent deployments..."
az webapp deployment list --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query "[0].{status:status,message:message,author:author,deployer:deployer}" -o table

echo ""
echo "3. Checking application logs (last 50 lines)..."
echo "If you see errors, that will help diagnose the issue."
echo ""
az webapp log tail --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --only-show-errors

echo ""
echo "4. To see all logs, run:"
echo "az webapp log tail --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST"
