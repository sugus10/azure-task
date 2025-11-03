#!/bin/bash

# Fix Traffic Manager endpoints after deployment

RESOURCE_GROUP_EAST="EastUSResourceGroup"
RESOURCE_GROUP_CENTRAL="CentralUSResourceGroup"
TIMESTAMP="1762147047"  # Update this with your timestamp

TRAFFIC_MANAGER_NAME="myTrafficManager$TIMESTAMP"
WEBAPP_EAST="EastUSWebApp$TIMESTAMP"
WEBAPP_CENTRAL="CentralUSWebApp$TIMESTAMP"

echo "Fixing Traffic Manager endpoints..."

# Get web app resource IDs and hostnames
EAST_WEBAPP_ID=$(az webapp show --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query id --output tsv)
CENTRAL_WEBAPP_ID=$(az webapp show --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL --query id --output tsv)

EAST_WEBAPP_HOSTNAME=$(az webapp show --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query defaultHostName --output tsv)
CENTRAL_WEBAPP_HOSTNAME=$(az webapp show --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL --query defaultHostName --output tsv)

if [ -z "$EAST_WEBAPP_ID" ] || [ -z "$CENTRAL_WEBAPP_ID" ]; then
    echo "Error: Could not get web app IDs"
    exit 1
fi

echo "East Web App ID: $EAST_WEBAPP_ID"
echo "East Web App Hostname: $EAST_WEBAPP_HOSTNAME"
echo "Central Web App ID: $CENTRAL_WEBAPP_ID"
echo "Central Web App Hostname: $CENTRAL_WEBAPP_HOSTNAME"
echo ""

# Delete existing endpoints if they exist
echo "Checking for existing endpoints..."
az network traffic-manager endpoint delete \
  --name "EastUSEndpoint" \
  --profile-name $TRAFFIC_MANAGER_NAME \
  --resource-group $RESOURCE_GROUP_EAST \
  --type azureEndpoints \
  --yes 2>/dev/null || echo "East endpoint doesn't exist or already deleted"

az network traffic-manager endpoint delete \
  --name "CentralUSEndpoint" \
  --profile-name $TRAFFIC_MANAGER_NAME \
  --resource-group $RESOURCE_GROUP_EAST \
  --type azureEndpoints \
  --yes 2>/dev/null || echo "Central endpoint doesn't exist or already deleted"

echo "Waiting for deletion to complete..."
sleep 5

# Add East US endpoint
echo "Adding East US endpoint..."
if az network traffic-manager endpoint show \
  --name "EastUSEndpoint" \
  --profile-name $TRAFFIC_MANAGER_NAME \
  --resource-group $RESOURCE_GROUP_EAST \
  --type azureEndpoints &>/dev/null; then
  # Update existing endpoint
  echo "Updating existing East US endpoint..."
  az network traffic-manager endpoint update \
    --name "EastUSEndpoint" \
    --profile-name $TRAFFIC_MANAGER_NAME \
    --resource-group $RESOURCE_GROUP_EAST \
    --type azureEndpoints \
    --target-resource-id "$EAST_WEBAPP_ID" \
    --endpoint-status Enabled \
    --priority 1 \
    --weight 1
else
  # Create new endpoint
  echo "Creating new East US endpoint..."
  az network traffic-manager endpoint create \
    --name "EastUSEndpoint" \
    --profile-name $TRAFFIC_MANAGER_NAME \
    --resource-group $RESOURCE_GROUP_EAST \
    --type azureEndpoints \
    --target-resource-id "$EAST_WEBAPP_ID" \
    --endpoint-status Enabled \
    --priority 1 \
    --weight 1
fi

# Add Central US endpoint
echo "Adding Central US endpoint..."
if az network traffic-manager endpoint show \
  --name "CentralUSEndpoint" \
  --profile-name $TRAFFIC_MANAGER_NAME \
  --resource-group $RESOURCE_GROUP_EAST \
  --type azureEndpoints &>/dev/null; then
  # Update existing endpoint
  echo "Updating existing Central US endpoint..."
  az network traffic-manager endpoint update \
    --name "CentralUSEndpoint" \
    --profile-name $TRAFFIC_MANAGER_NAME \
    --resource-group $RESOURCE_GROUP_EAST \
    --type azureEndpoints \
    --target-resource-id "$CENTRAL_WEBAPP_ID" \
    --endpoint-status Enabled \
    --priority 1 \
    --weight 1
else
  # Create new endpoint
  echo "Creating new Central US endpoint..."
  az network traffic-manager endpoint create \
    --name "CentralUSEndpoint" \
    --profile-name $TRAFFIC_MANAGER_NAME \
    --resource-group $RESOURCE_GROUP_EAST \
    --type azureEndpoints \
    --target-resource-id "$CENTRAL_WEBAPP_ID" \
    --endpoint-status Enabled \
    --priority 1 \
    --weight 1
fi

echo ""
echo "Traffic Manager endpoints configured!"
echo "Traffic Manager URL: https://mytrafficmanager$TIMESTAMP.trafficmanager.net"

