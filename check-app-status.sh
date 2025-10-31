#!/bin/bash

WEBAPP_EAST="EastUSWebApp1761914463"
RESOURCE_GROUP_EAST="EastUSResourceGroup"

echo "Checking application status and configuration..."

echo "1. Checking web app state..."
az webapp show --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query "{state:state,defaultHostName:defaultHostName,kind:kind}" -o table

echo ""
echo "2. Checking startup command..."
az webapp config show --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query "appCommandLine" -o tsv

echo ""
echo "3. Checking Node.js version setting..."
az webapp config appsettings list --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query "[?name=='WEBSITE_NODE_DEFAULT_VERSION'].{name:name,value:value}" -o table

echo ""
echo "4. Checking if there are any error logs in the console..."
echo "Run this command to see detailed error logs:"
echo "az webapp log download --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --log-file app-logs.zip"
