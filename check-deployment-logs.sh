#!/bin/bash

WEBAPP_EAST="EastUSWebApp1761914463"
RESOURCE_GROUP_EAST="EastUSResourceGroup"

echo "Checking deployment logs..."

# Get the latest deployment ID
DEPLOYMENT_ID=$(az webapp deployment list --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query "[0].id" -o tsv)

if [ ! -z "$DEPLOYMENT_ID" ]; then
    echo "Latest deployment ID: $DEPLOYMENT_ID"
    echo ""
    echo "Getting deployment log URL..."
    LOG_URL=$(az webapp deployment show --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --deployment-id $DEPLOYMENT_ID --query "log_url" -o tsv)
    echo "Deployment log URL: $LOG_URL"
    echo ""
    echo "You can visit this URL in your browser to see the deployment logs"
fi

echo ""
echo "Downloading all logs..."
az webapp log download --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --log-file app-logs.zip

echo ""
echo "Logs downloaded to app-logs.zip"
echo "Extract it and check the LogFiles/Application/ directory for application logs"
