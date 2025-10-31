#!/bin/bash

# Variables
RESOURCE_GROUP_EAST="EastUSResourceGroup"
RESOURCE_GROUP_CENTRAL="CentralUSResourceGroup"
LOCATION_EAST="eastus"
LOCATION_CENTRAL="centralus"
# Using West US for SQL Database since East US is not available
LOCATION_SQL="westus"
RESOURCE_GROUP_SQL="WestUSResourceGroup"
APP_SERVICE_PLAN_EAST="EastUSAppServicePlan"
APP_SERVICE_PLAN_CENTRAL="CentralUSAppServicePlan"
WEBAPP_EAST="EastUSWebApp"
WEBAPP_CENTRAL="CentralUSWebApp"
KEY_VAULT_NAME="MyKeyVault$(date +%s)"  # Adding timestamp for uniqueness
SQL_SERVER_NAME="sqlserver$(date +%s)"  # Adding timestamp for uniqueness
SQL_DB_NAME="myDatabase"
SQL_ADMIN_USER="sqladmin"
SQL_ADMIN_PASSWORD="P@ssw0rd$(date +%s)"  # Adding timestamp for uniqueness
SECRET_NAME="name_surname_1"
TRAFFIC_MANAGER_NAME="myTrafficManager$(date +%s)"  # Adding timestamp for uniqueness
TRAFFIC_MANAGER_DNS="mytrafficmanager$(date +%s)"  # Adding timestamp for uniqueness

echo "Starting Azure infrastructure deployment..."

# 1. Create Resource Groups
echo "Creating Resource Groups..."
az group create --name $RESOURCE_GROUP_EAST --location $LOCATION_EAST
az group create --name $RESOURCE_GROUP_CENTRAL --location $LOCATION_CENTRAL
az group create --name $RESOURCE_GROUP_SQL --location $LOCATION_SQL

# 2. Create App Service Plans
echo "Creating App Service Plans..."
az appservice plan create --name $APP_SERVICE_PLAN_EAST --resource-group $RESOURCE_GROUP_EAST --location $LOCATION_EAST --sku S1
az appservice plan create --name $APP_SERVICE_PLAN_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL --location $LOCATION_CENTRAL --sku S1

# 3. Create Web Apps
echo "Creating Web Apps..."
az webapp create --name $WEBAPP_EAST --plan $APP_SERVICE_PLAN_EAST --resource-group $RESOURCE_GROUP_EAST
az webapp create --name $WEBAPP_CENTRAL --plan $APP_SERVICE_PLAN_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL

# 4. Enable Managed Identity for Web Apps
echo "Enabling Managed Identity for Web Apps..."
EAST_PRINCIPAL_ID=$(az webapp identity assign --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query principalId --output tsv)
CENTRAL_PRINCIPAL_ID=$(az webapp identity assign --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL --query principalId --output tsv)

# 5. Create Key Vault
echo "Creating Key Vault..."
az keyvault create --name $KEY_VAULT_NAME --resource-group $RESOURCE_GROUP_EAST --location $LOCATION_EAST

# 6. Create SQL Server and Database in West US (since East US is not available)
echo "Creating SQL Server and Database in West US..."
az sql server create --name $SQL_SERVER_NAME --resource-group $RESOURCE_GROUP_SQL --location $LOCATION_SQL --admin-user $SQL_ADMIN_USER --admin-password $SQL_ADMIN_PASSWORD

# Allow Azure services to access the server
az sql server firewall-rule create --name "AllowAzureServices" --server $SQL_SERVER_NAME --resource-group $RESOURCE_GROUP_SQL --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

# Create SQL Database
az sql db create --name $SQL_DB_NAME --server $SQL_SERVER_NAME --resource-group $RESOURCE_GROUP_SQL --service-objective S0

# 7. Generate SQL Connection String and store in Key Vault
echo "Storing SQL Connection String in Key Vault..."
SQL_CONNECTION_STRING="Server=tcp:$SQL_SERVER_NAME.database.windows.net,1433;Initial Catalog=$SQL_DB_NAME;Persist Security Info=False;User ID=$SQL_ADMIN_USER;Password=$SQL_ADMIN_PASSWORD;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
az keyvault secret set --vault-name $KEY_VAULT_NAME --name $SECRET_NAME --value "$SQL_CONNECTION_STRING"

# 8. Configure Key Vault Access Policies for Web Apps
echo "Configuring Key Vault Access Policies..."
az keyvault set-policy --name $KEY_VAULT_NAME --object-id $EAST_PRINCIPAL_ID --secret-permissions get list
az keyvault set-policy --name $KEY_VAULT_NAME --object-id $CENTRAL_PRINCIPAL_ID --secret-permissions get list

# 9. Add Application Settings to Web Apps
echo "Configuring Web App Application Settings..."
az webapp config appsettings set --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --settings "ConnectionString=@Microsoft.KeyVault(VaultName=$KEY_VAULT_NAME;SecretName=$SECRET_NAME;SecretVersion=)"
az webapp config appsettings set --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL --settings "ConnectionString=@Microsoft.KeyVault(VaultName=$KEY_VAULT_NAME;SecretName=$SECRET_NAME;SecretVersion=)"

# 10. Create Traffic Manager Profile with Performance routing method
echo "Creating Traffic Manager Profile..."
az network traffic-manager profile create --name $TRAFFIC_MANAGER_NAME --resource-group $RESOURCE_GROUP_EAST --routing-method Performance --unique-dns-name $TRAFFIC_MANAGER_DNS --ttl 30

# 11. Add Web Apps as Endpoints to Traffic Manager
echo "Adding Web Apps as Endpoints to Traffic Manager..."
EAST_WEBAPP_ID=$(az webapp show --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query id --output tsv)
CENTRAL_WEBAPP_ID=$(az webapp show --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL --query id --output tsv)

az network traffic-manager endpoint create --name "EastUSEndpoint" --profile-name $TRAFFIC_MANAGER_NAME --resource-group $RESOURCE_GROUP_EAST --type azureEndpoints --target-resource-id $EAST_WEBAPP_ID --endpoint-status Enabled
az network traffic-manager endpoint create --name "CentralUSEndpoint" --profile-name $TRAFFIC_MANAGER_NAME --resource-group $RESOURCE_GROUP_EAST --type azureEndpoints --target-resource-id $CENTRAL_WEBAPP_ID --endpoint-status Enabled

echo "Infrastructure deployment completed successfully!"
echo "Key Vault Name: $KEY_VAULT_NAME"
echo "SQL Server Name: $SQL_SERVER_NAME"
echo "Traffic Manager DNS: $TRAFFIC_MANAGER_DNS.trafficmanager.net"
