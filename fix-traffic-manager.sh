#!/bin/bash

# Fix Traffic Manager endpoints after deployment

RESOURCE_GROUP_EAST="EastUSResourceGroup"
RESOURCE_GROUP_CENTRAL="CentralUSResourceGroup"
TIMESTAMP="1762147047"  # Update this with your timestamp

TRAFFIC_MANAGER_NAME="myTrafficManager$TIMESTAMP"
WEBAPP_EAST="EastUSWebApp$TIMESTAMP"
WEBAPP_CENTRAL="CentralUSWebApp$TIMESTAMP"

echo "Fixing Traffic Manager endpoints..."

# Get web app resource IDs
EAST_WEBAPP_ID=$(az webapp show --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query id --output tsv)
CENTRAL_WEBAPP_ID=$(az webapp show --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL --query id --output tsv)

if [ -z "$EAST_WEBAPP_ID" ] || [ -z "$CENTRAL_WEBAPP_ID" ]; then
    echo "Error: Could not get web app IDs"
    exit 1
fi

echo "East Web App ID: $EAST_WEBAPP_ID"
echo "Central Web App ID: $CENTRAL_WEBAPP_ID"
echo ""

# Add East US endpoint
echo "Adding East US endpoint..."
az network traffic-manager endpoint create \
  --name "EastUSEndpoint" \
  --profile-name $TRAFFIC_MANAGER_NAME \
  --resource-group $RESOURCE_GROUP_EAST \
  --type azureEndpoints \
  --target-resource-id "$EAST_WEBAPP_ID" \
  --endpoint-status Enabled \
  --priority 1 \
  --weight 1

# Add Central US endpoint
echo "Adding Central US endpoint..."
az network traffic-manager endpoint create \
  --name "CentralUSEndpoint" \
  --profile-name $TRAFFIC_MANAGER_NAME \
  --resource-group $RESOURCE_GROUP_EAST \
  --type azureEndpoints \
  --target-resource-id "$CENTRAL_WEBAPP_ID" \
  --endpoint-status Enabled \
  --priority 1 \
  --weight 1

echo ""
echo "Traffic Manager endpoints configured!"
echo "Traffic Manager URL: https://mytrafficmanager$TIMESTAMP.trafficmanager.net"

