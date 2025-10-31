#!/bin/bash

# Variables
WEBAPP_EAST="EastUSWebApp1761895912"
WEBAPP_CENTRAL="CentralUSWebApp1761895912"
RESOURCE_GROUP_EAST="EastUSResourceGroup"
RESOURCE_GROUP_CENTRAL="CentralUSResourceGroup"

echo "Restarting web apps..."

# Restart East US Web App
echo "Restarting East US Web App..."
az webapp restart --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST

# Restart Central US Web App
echo "Restarting Central US Web App..."
az webapp restart --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL

echo "Web apps restarted successfully!"
echo ""
echo "Wait about 30 seconds and then access the website at:"
echo "East US: https://$WEBAPP_EAST.azurewebsites.net"
echo "Central US: https://$WEBAPP_CENTRAL.azurewebsites.net"
echo "Traffic Manager: https://mytrafficmanager1761895913.trafficmanager.net"
