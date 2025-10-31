#!/bin/bash

# Variables
RESOURCE_GROUP_EAST="EastUSResourceGroup"
RESOURCE_GROUP_CENTRAL="CentralUSResourceGroup"
LOCATION_EAST="eastus"
WEBAPP_EAST="EastUSWebApp1761895912"
WEBAPP_CENTRAL="CentralUSWebApp1761895912"
SQL_SERVER_NAME="sqlserver1761895912"
SQL_DB_NAME="myDatabase"
SQL_ADMIN_USER="sqladmin"
SQL_ADMIN_PASSWORD="P@ssw0rd1761895912"  # Replace with your actual password
SECRET_NAME="namesurname1"
TIMESTAMP=$(date +%s)
KEY_VAULT_NAME="MyKeyVault$TIMESTAMP"

echo "Starting Key Vault setup with access policies..."

# 1. Create a new Key Vault without RBAC authorization
echo "Creating new Key Vault without RBAC authorization..."
az keyvault create --name $KEY_VAULT_NAME \
  --resource-group $RESOURCE_GROUP_EAST \
  --location $LOCATION_EAST \
  --enable-rbac-authorization false

echo "Key Vault created: $KEY_VAULT_NAME"

# 2. Create SQL connection string
echo "Creating SQL connection string..."
SQL_CONNECTION_STRING="Server=tcp:$SQL_SERVER_NAME.database.windows.net,1433;Initial Catalog=$SQL_DB_NAME;Persist Security Info=False;User ID=$SQL_ADMIN_USER;Password=$SQL_ADMIN_PASSWORD;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

# 3. Store the connection string in Key Vault
echo "Storing connection string in Key Vault..."
az keyvault secret set --vault-name $KEY_VAULT_NAME --name $SECRET_NAME --value "$SQL_CONNECTION_STRING"

# 4. Enable managed identity for both web apps
echo "Enabling managed identity for East US Web App..."
EAST_PRINCIPAL_ID=$(az webapp identity assign --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query principalId --output tsv)
echo "East Web App Principal ID: $EAST_PRINCIPAL_ID"

echo "Enabling managed identity for Central US Web App..."
CENTRAL_PRINCIPAL_ID=$(az webapp identity assign --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL --query principalId --output tsv)
echo "Central Web App Principal ID: $CENTRAL_PRINCIPAL_ID"

# 5. Set access policies for both web apps
echo "Setting Key Vault access policy for East US Web App..."
az keyvault set-policy --name $KEY_VAULT_NAME --object-id $EAST_PRINCIPAL_ID --secret-permissions get list

echo "Setting Key Vault access policy for Central US Web App..."
az keyvault set-policy --name $KEY_VAULT_NAME --object-id $CENTRAL_PRINCIPAL_ID --secret-permissions get list

# 6. Configure web apps to use Key Vault reference
echo "Configuring East US Web App to use Key Vault reference..."
az webapp config appsettings set --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST \
  --settings "ConnectionString=@Microsoft.KeyVault(VaultName=$KEY_VAULT_NAME;SecretName=$SECRET_NAME;SecretVersion=)"

echo "Configuring Central US Web App to use Key Vault reference..."
az webapp config appsettings set --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL \
  --settings "ConnectionString=@Microsoft.KeyVault(VaultName=$KEY_VAULT_NAME;SecretName=$SECRET_NAME;SecretVersion=)"

# 7. Deploy the application to both web apps
echo "Deploying application to East US Web App..."
az webapp deployment source config-zip --resource-group $RESOURCE_GROUP_EAST --name $WEBAPP_EAST --src deployment.zip

echo "Deploying application to Central US Web App..."
az webapp deployment source config-zip --resource-group $RESOURCE_GROUP_CENTRAL --name $WEBAPP_CENTRAL --src deployment.zip

echo "Setup completed successfully!"
echo ""
echo "Key Vault Name: $KEY_VAULT_NAME"
echo "Secret Name: $SECRET_NAME"
echo ""
echo "Your application is now available at:"
echo "East US: https://$WEBAPP_EAST.azurewebsites.net"
echo "Central US: https://$WEBAPP_CENTRAL.azurewebsites.net"
echo "Traffic Manager: https://mytrafficmanager1761895913.trafficmanager.net"
