#!/bin/bash

# Variables - replace with your actual values from the infrastructure output
KEY_VAULT_NAME="MyKeyVault1761895912"
RESOURCE_GROUP_EAST="EastUSResourceGroup"
RESOURCE_GROUP_CENTRAL="CentralUSResourceGroup"
SUBSCRIPTION_ID="23669202-df8d-4f9f-a1a0-09e42368c316"
WEBAPP_EAST="EastUSWebApp1761895912"
WEBAPP_CENTRAL="CentralUSWebApp1761895912"
SQL_SERVER_NAME="sqlserver1761895912"
SQL_DB_NAME="myDatabase"
SQL_ADMIN_USER="sqladmin"
SQL_ADMIN_PASSWORD="P@ssw0rd1761895912"  # Replace with your actual password
SECRET_NAME="namesurname1"

echo "Starting Key Vault permissions fix..."

# 1. Get the current user's object ID
echo "Getting current user's object ID..."
USER_ID=$(az ad signed-in-user show --query id -o tsv)
echo "User ID: $USER_ID"

# 2. Assign Key Vault Secrets Officer role to the current user
echo "Assigning Key Vault Secrets Officer role to current user..."
az role assignment create --role "Key Vault Secrets Officer" \
  --assignee $USER_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_EAST/providers/Microsoft.KeyVault/vaults/$KEY_VAULT_NAME"

# 3. Create SQL connection string
echo "Creating SQL connection string..."
SQL_CONNECTION_STRING="Server=tcp:$SQL_SERVER_NAME.database.windows.net,1433;Initial Catalog=$SQL_DB_NAME;Persist Security Info=False;User ID=$SQL_ADMIN_USER;Password=$SQL_ADMIN_PASSWORD;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

# 4. Set the secret in Key Vault
echo "Storing connection string in Key Vault..."
az keyvault secret set --vault-name $KEY_VAULT_NAME --name $SECRET_NAME --value "$SQL_CONNECTION_STRING"

# 5. Enable managed identity for both web apps if not already enabled
echo "Enabling managed identity for Web Apps..."
EAST_PRINCIPAL_ID=$(az webapp identity assign --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query principalId --output tsv)
echo "East Web App Principal ID: $EAST_PRINCIPAL_ID"

CENTRAL_PRINCIPAL_ID=$(az webapp identity assign --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL --query principalId --output tsv)
echo "Central Web App Principal ID: $CENTRAL_PRINCIPAL_ID"

# 6. Assign Key Vault Secrets User role to the web apps
echo "Assigning Key Vault Secrets User role to Web Apps..."
az role assignment create --role "Key Vault Secrets User" \
  --assignee $EAST_PRINCIPAL_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_EAST/providers/Microsoft.KeyVault/vaults/$KEY_VAULT_NAME"

az role assignment create --role "Key Vault Secrets User" \
  --assignee $CENTRAL_PRINCIPAL_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP_EAST/providers/Microsoft.KeyVault/vaults/$KEY_VAULT_NAME"

# 7. Configure web apps to use the Key Vault reference
echo "Configuring Web Apps to use Key Vault reference..."
az webapp config appsettings set --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST \
  --settings "ConnectionString=@Microsoft.KeyVault(VaultName=$KEY_VAULT_NAME;SecretName=$SECRET_NAME;SecretVersion=)"

az webapp config appsettings set --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL \
  --settings "ConnectionString=@Microsoft.KeyVault(VaultName=$KEY_VAULT_NAME;SecretName=$SECRET_NAME;SecretVersion=)"

echo "Key Vault permissions fixed successfully!"
echo "Now you can deploy your application using the deployment.zip file."
echo ""
echo "To deploy your application, run:"
echo "az webapp deployment source config-zip --resource-group $RESOURCE_GROUP_EAST --name $WEBAPP_EAST --src deployment.zip"
echo "az webapp deployment source config-zip --resource-group $RESOURCE_GROUP_CENTRAL --name $WEBAPP_CENTRAL --src deployment.zip"
