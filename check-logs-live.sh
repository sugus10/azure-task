#!/bin/bash

# Variables
WEBAPP_EAST="EastUSWebApp1761895912"
RESOURCE_GROUP_EAST="EastUSResourceGroup"

echo "Checking live logs for the East US Web App..."
echo "This will show real-time logs. Press Ctrl+C to exit when done."
echo ""

# Stream the logs
az webapp log tail --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST
