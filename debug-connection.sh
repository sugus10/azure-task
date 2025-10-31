#!/bin/bash

# Debug script to check web app configuration

WEBAPP_EAST="EastUSWebApp1761914463"
RESOURCE_GROUP_EAST="EastUSResourceGroup"

echo "Checking Web App Configuration..."
echo ""

# Check application settings
echo "1. Application Settings:"
az webapp config appsettings list --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --output table

echo ""
echo "2. Checking if connection string is resolving correctly..."
echo "This might take a moment..."

# Get the connection string value (it should show the Key Vault reference)
CONNECTION_STRING=$(az webapp config appsettings list --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query "[?name=='ConnectionString'].value" -o tsv)

echo "ConnectionString setting value: $CONNECTION_STRING"

echo ""
echo "3. Restarting the web app to ensure it picks up the connection string..."
az webapp restart --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST

echo ""
echo "4. After restart, check the logs:"
echo "az webapp log tail --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST"
