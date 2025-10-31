#!/bin/bash

# Variables - Change these if needed
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RESOURCE_GROUP_EAST="EastUSResourceGroup"
RESOURCE_GROUP_CENTRAL="CentralUSResourceGroup"
RESOURCE_GROUP_WEST="WestUSResourceGroup"
LOCATION_EAST="eastus"
LOCATION_CENTRAL="centralus"
LOCATION_WEST="westus"
TIMESTAMP=$(date +%s)
APP_SERVICE_PLAN_EAST="EastUSAppServicePlan"
APP_SERVICE_PLAN_CENTRAL="CentralUSAppServicePlan"
WEBAPP_EAST="EastUSWebApp$TIMESTAMP"
WEBAPP_CENTRAL="CentralUSWebApp$TIMESTAMP"
KEY_VAULT_NAME="MyKeyVault$TIMESTAMP"
SQL_SERVER_NAME="sqlserver$TIMESTAMP"
SQL_DB_NAME="myDatabase"
SQL_ADMIN_USER="sqladmin"
SQL_ADMIN_PASSWORD="P@ssw0rd$TIMESTAMP"
SECRET_NAME="namesurname1"
TRAFFIC_MANAGER_NAME="myTrafficManager$TIMESTAMP"
TRAFFIC_MANAGER_DNS="mytrafficmanager$TIMESTAMP"

echo "Starting Azure infrastructure deployment..."

# 1. Create Resource Groups
echo "Creating Resource Groups..."
az group create --name $RESOURCE_GROUP_EAST --location $LOCATION_EAST
az group create --name $RESOURCE_GROUP_CENTRAL --location $LOCATION_CENTRAL
az group create --name $RESOURCE_GROUP_WEST --location $LOCATION_WEST

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
echo "East Web App Principal ID: $EAST_PRINCIPAL_ID"

CENTRAL_PRINCIPAL_ID=$(az webapp identity assign --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL --query principalId --output tsv)
echo "Central Web App Principal ID: $CENTRAL_PRINCIPAL_ID"

# 5. Create Key Vault with access policies (not RBAC)
echo "Creating Key Vault..."
az keyvault create --name $KEY_VAULT_NAME --resource-group $RESOURCE_GROUP_EAST --location $LOCATION_EAST --enable-rbac-authorization false

# 6. Create SQL Server and Database in West US
echo "Creating SQL Server and Database in West US..."
az sql server create --name $SQL_SERVER_NAME --resource-group $RESOURCE_GROUP_WEST --location $LOCATION_WEST --admin-user $SQL_ADMIN_USER --admin-password $SQL_ADMIN_PASSWORD

# Allow Azure services to access the server
echo "Allowing Azure services to access SQL Server..."
az sql server firewall-rule create --name "AllowAzureServices" --server $SQL_SERVER_NAME --resource-group $RESOURCE_GROUP_WEST --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0

# Create SQL Database
echo "Creating SQL Database..."
az sql db create --name $SQL_DB_NAME --server $SQL_SERVER_NAME --resource-group $RESOURCE_GROUP_WEST --service-objective S0

# 7. Store SQL Connection String in Key Vault
echo "Storing SQL Connection String in Key Vault..."
SQL_CONNECTION_STRING="Server=tcp:$SQL_SERVER_NAME.database.windows.net,1433;Initial Catalog=$SQL_DB_NAME;Persist Security Info=False;User ID=$SQL_ADMIN_USER;Password=$SQL_ADMIN_PASSWORD;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"

az keyvault secret set --vault-name $KEY_VAULT_NAME --name $SECRET_NAME --value "$SQL_CONNECTION_STRING"

# 8. Set Key Vault Access Policies for Web Apps
echo "Setting Key Vault Access Policies for Web Apps..."
az keyvault set-policy --name $KEY_VAULT_NAME --object-id $EAST_PRINCIPAL_ID --secret-permissions get list
az keyvault set-policy --name $KEY_VAULT_NAME --object-id $CENTRAL_PRINCIPAL_ID --secret-permissions get list

# 9. Configure Web Apps to use Key Vault Reference
echo "Configuring Web Apps to use Key Vault Reference..."
az webapp config appsettings set --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST \
  --settings "ConnectionString=@Microsoft.KeyVault(VaultName=$KEY_VAULT_NAME;SecretName=$SECRET_NAME;SecretVersion=)" \
  "WEBSITE_NODE_DEFAULT_VERSION=~16"

az webapp config appsettings set --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL \
  --settings "ConnectionString=@Microsoft.KeyVault(VaultName=$KEY_VAULT_NAME;SecretName=$SECRET_NAME;SecretVersion=)" \
  "WEBSITE_NODE_DEFAULT_VERSION=~16"

# 10. Create Traffic Manager Profile
echo "Creating Traffic Manager Profile..."
az network traffic-manager profile create --name $TRAFFIC_MANAGER_NAME --resource-group $RESOURCE_GROUP_EAST --routing-method Performance --unique-dns-name $TRAFFIC_MANAGER_DNS --ttl 30

# 11. Add Web Apps as Endpoints to Traffic Manager
echo "Adding Web Apps as Endpoints to Traffic Manager..."
EAST_WEBAPP_ID=$(az webapp show --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query id --output tsv)
CENTRAL_WEBAPP_ID=$(az webapp show --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL --query id --output tsv)

az network traffic-manager endpoint create --name "EastUSEndpoint" --profile-name $TRAFFIC_MANAGER_NAME --resource-group $RESOURCE_GROUP_EAST --type azureEndpoints --target-resource-id "$EAST_WEBAPP_ID" --endpoint-status Enabled
az network traffic-manager endpoint create --name "CentralUSEndpoint" --profile-name $TRAFFIC_MANAGER_NAME --resource-group $RESOURCE_GROUP_EAST --type azureEndpoints --target-resource-id "$CENTRAL_WEBAPP_ID" --endpoint-status Enabled

# 12. Create SQL script for database setup
echo "Creating SQL script for database setup..."
cat > setup-database.sql << EOF
-- Check if Items table exists, if not create it
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Items' and xtype='U')
BEGIN
    CREATE TABLE Items (
        id INT PRIMARY KEY IDENTITY(1,1),
        name NVARCHAR(100) NOT NULL,
        description NVARCHAR(500),
        createdAt DATETIME NOT NULL,
        updatedAt DATETIME
    );
    
    -- Insert sample data
    INSERT INTO Items (name, description, createdAt)
    VALUES 
        ('Sample Item 1', 'This is a sample item for demonstration', GETDATE()),
        ('Sample Item 2', 'Another example item to show CRUD functionality', GETDATE()),
        ('Sample Item 3', 'A third item to populate the initial view', GETDATE());
END
EOF

# 13. Create deployment package
echo "Creating deployment package..."
if command -v zip &> /dev/null; then
    zip -r deployment.zip server.js package.json public/
else
    # Fallback to PowerShell for Windows environments
    echo "zip command not found, using PowerShell instead..."
    powershell -Command "Compress-Archive -Path server.js,package.json,public/* -DestinationPath deployment.zip -Force"
fi

# 14. Deploy the application to both Web Apps
echo "Deploying application to Web Apps..."
az webapp deployment source config-zip --resource-group $RESOURCE_GROUP_EAST --name $WEBAPP_EAST --src deployment.zip
az webapp deployment source config-zip --resource-group $RESOURCE_GROUP_CENTRAL --name $WEBAPP_CENTRAL --src deployment.zip

echo "Infrastructure deployment completed successfully!"
echo ""
echo "IMPORTANT: You need to set up the database table manually using the Azure Portal Query Editor."
echo "1. Go to the Azure Portal"
echo "2. Find your SQL database: $SQL_DB_NAME on server $SQL_SERVER_NAME"
echo "3. Open the Query Editor"
echo "4. Login with username: $SQL_ADMIN_USER and password: $SQL_ADMIN_PASSWORD"
echo "5. Run the SQL script in the file: setup-database.sql"
echo ""
echo "Resource Names:"
echo "Web App (East US): $WEBAPP_EAST"
echo "Web App (Central US): $WEBAPP_CENTRAL"
echo "Key Vault: $KEY_VAULT_NAME"
echo "SQL Server: $SQL_SERVER_NAME"
echo "SQL Database: $SQL_DB_NAME"
echo "Traffic Manager: $TRAFFIC_MANAGER_DNS.trafficmanager.net"
echo ""
echo "After setting up the database table, your application will be available at:"
echo "https://$WEBAPP_EAST.azurewebsites.net"
echo "https://$WEBAPP_CENTRAL.azurewebsites.net"
echo "https://$TRAFFIC_MANAGER_DNS.trafficmanager.net"
