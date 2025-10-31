#!/bin/bash

# Variables
WEBAPP_EAST="EastUSWebApp1761895912"
WEBAPP_CENTRAL="CentralUSWebApp1761895912"
RESOURCE_GROUP_EAST="EastUSResourceGroup"
RESOURCE_GROUP_CENTRAL="CentralUSResourceGroup"
KEY_VAULT_NAME="MyKeyVault1761895912"  # Replace with your actual Key Vault name
SECRET_NAME="namesurname1"

echo "Updating web app settings to fix connection issues..."

# 1. Check if the web apps exist
echo "Checking if web apps exist..."
EAST_EXISTS=$(az webapp show --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query name --output tsv 2>/dev/null)
CENTRAL_EXISTS=$(az webapp show --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL --query name --output tsv 2>/dev/null)

if [ -z "$EAST_EXISTS" ] || [ -z "$CENTRAL_EXISTS" ]; then
    echo "Error: One or both web apps not found. Please check the names."
    exit 1
fi

# 2. Update the application settings for East US Web App
echo "Updating East US Web App settings..."
az webapp config appsettings set --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST \
  --settings "ConnectionString=@Microsoft.KeyVault(VaultName=$KEY_VAULT_NAME;SecretName=$SECRET_NAME;SecretVersion=)" \
  "WEBSITE_NODE_DEFAULT_VERSION=~16" \
  "SCM_DO_BUILD_DURING_DEPLOYMENT=true"

# 3. Update the application settings for Central US Web App
echo "Updating Central US Web App settings..."
az webapp config appsettings set --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL \
  --settings "ConnectionString=@Microsoft.KeyVault(VaultName=$KEY_VAULT_NAME;SecretName=$SECRET_NAME;SecretVersion=)" \
  "WEBSITE_NODE_DEFAULT_VERSION=~16" \
  "SCM_DO_BUILD_DURING_DEPLOYMENT=true"

# 4. Restart the web apps to apply changes
echo "Restarting East US Web App..."
az webapp restart --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST

echo "Restarting Central US Web App..."
az webapp restart --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL

echo "Web app settings updated successfully!"
echo ""
echo "Your application should now be accessible at:"
echo "East US: https://$WEBAPP_EAST.azurewebsites.net"
echo "Central US: https://$WEBAPP_CENTRAL.azurewebsites.net"
echo "Traffic Manager: https://mytrafficmanager1761895913.trafficmanager.net"
