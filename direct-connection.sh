#!/bin/bash

# Variables
WEBAPP_EAST="EastUSWebApp1761895912"
WEBAPP_CENTRAL="CentralUSWebApp1761895912"
RESOURCE_GROUP_EAST="EastUSResourceGroup"
RESOURCE_GROUP_CENTRAL="CentralUSResourceGroup"
SQL_SERVER_NAME="sqlserver1761895912"
SQL_DB_NAME="myDatabase"
SQL_ADMIN_USER="sqladmin"
SQL_ADMIN_PASSWORD="P@ssw0rd1761895912"  # Replace with your actual password

echo "Setting up direct database connection (bypassing Key Vault)..."

# 1. Configure East US Web App with direct connection settings
echo "Configuring East US Web App..."
az webapp config appsettings set --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST \
  --settings "DB_SERVER=$SQL_SERVER_NAME.database.windows.net" \
             "DB_DATABASE=$SQL_DB_NAME" \
             "DB_USER=$SQL_ADMIN_USER" \
             "DB_PASSWORD=$SQL_ADMIN_PASSWORD" \
             "DB_PORT=1433" \
             "WEBSITE_NODE_DEFAULT_VERSION=~16" \
             "SCM_DO_BUILD_DURING_DEPLOYMENT=true"

# 2. Configure Central US Web App with direct connection settings
echo "Configuring Central US Web App..."
az webapp config appsettings set --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL \
  --settings "DB_SERVER=$SQL_SERVER_NAME.database.windows.net" \
             "DB_DATABASE=$SQL_DB_NAME" \
             "DB_USER=$SQL_ADMIN_USER" \
             "DB_PASSWORD=$SQL_ADMIN_PASSWORD" \
             "DB_PORT=1433" \
             "WEBSITE_NODE_DEFAULT_VERSION=~16" \
             "SCM_DO_BUILD_DURING_DEPLOYMENT=true"

# 3. Restart the web apps to apply changes
echo "Restarting East US Web App..."
az webapp restart --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST

echo "Restarting Central US Web App..."
az webapp restart --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL

echo "Direct database connection setup completed!"
echo ""
echo "Your application should now be accessible at:"
echo "East US: https://$WEBAPP_EAST.azurewebsites.net"
echo "Central US: https://$WEBAPP_CENTRAL.azurewebsites.net"
