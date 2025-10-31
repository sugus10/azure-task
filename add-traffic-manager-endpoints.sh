#!/bin/bash

# Variables
RESOURCE_GROUP_EAST="EastUSResourceGroup"
RESOURCE_GROUP_CENTRAL="CentralUSResourceGroup"
WEBAPP_EAST="EastUSWebApp1761895912"
WEBAPP_CENTRAL="CentralUSWebApp1761895912"
TRAFFIC_MANAGER_NAME="myTrafficManager1761895912"

echo "Adding Web Apps as endpoints to Traffic Manager..."

# 1. Get the resource IDs of the web apps
echo "Getting resource IDs of the web apps..."
EAST_WEBAPP_ID=$(az webapp show --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query id --output tsv)
echo "East Web App ID: $EAST_WEBAPP_ID"

CENTRAL_WEBAPP_ID=$(az webapp show --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL --query id --output tsv)
echo "Central Web App ID: $CENTRAL_WEBAPP_ID"

# 2. Add the East US Web App as an endpoint to Traffic Manager
echo "Adding East US Web App as an endpoint..."
az network traffic-manager endpoint create \
  --name "EastUSEndpoint" \
  --profile-name $TRAFFIC_MANAGER_NAME \
  --resource-group $RESOURCE_GROUP_EAST \
  --type azureEndpoints \
  --target-resource-id $EAST_WEBAPP_ID \
  --endpoint-status Enabled

# 3. Add the Central US Web App as an endpoint to Traffic Manager
echo "Adding Central US Web App as an endpoint..."
az network traffic-manager endpoint create \
  --name "CentralUSEndpoint" \
  --profile-name $TRAFFIC_MANAGER_NAME \
  --resource-group $RESOURCE_GROUP_EAST \
  --type azureEndpoints \
  --target-resource-id $CENTRAL_WEBAPP_ID \
  --endpoint-status Enabled

echo "Traffic Manager endpoints added successfully!"
echo "Your application is now available through Traffic Manager at:"
echo "https://mytrafficmanager1761895913.trafficmanager.net"
