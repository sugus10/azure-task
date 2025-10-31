#!/bin/bash

# Variables
WEBAPP_EAST="EastUSWebApp1761895912"
RESOURCE_GROUP_EAST="EastUSResourceGroup"

echo "Checking logs for the East US Web App..."
echo "This will help diagnose the 404 error issue."

# Get the web app logs
az webapp log tail --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST
