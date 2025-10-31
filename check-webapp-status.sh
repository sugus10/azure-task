#!/bin/bash

# Variables
WEBAPP_EAST="EastUSWebApp1761895912"
RESOURCE_GROUP_EAST="EastUSResourceGroup"

echo "Checking status of the East US Web App..."

# 1. Check if the web app is running
echo "Checking if the web app is running..."
APP_STATE=$(az webapp show --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query state --output tsv)
echo "Web App State: $APP_STATE"

# 2. Check the app settings to verify the Key Vault reference
echo "Checking app settings..."
az webapp config appsettings list --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST

# 3. Check if the web app can access the Key Vault
echo "Checking if web app can access Key Vault..."
az webapp identity show --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST

# 4. Get the web app URL
WEBAPP_URL="https://$WEBAPP_EAST.azurewebsites.net"
echo "Web App URL: $WEBAPP_URL"

# 5. Check if the web app is accessible
echo "Checking if the web app is accessible..."
echo "Try opening this URL in your browser: $WEBAPP_URL"

# 6. Check the web app logs
echo "Checking web app logs (last 100 lines)..."
az webapp log download --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --log-file webapp.log
echo "Log file downloaded as webapp.log"

echo "Status check completed!"
echo "If the website is still showing 'not found', try the following:"
echo "1. Make sure the SQL Server firewall allows Azure services"
echo "2. Check if the Items table exists in the database"
echo "3. Check the web app logs for any errors"
echo "4. Try restarting the web app: az webapp restart --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST"
