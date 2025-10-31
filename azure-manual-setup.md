# Azure High Availability CRUD Application - Manual Setup Guide

This guide provides step-by-step instructions for manually setting up a highly available CRUD application on Azure using App Services, Traffic Manager, Key Vault, and SQL Database.

## Task Requirements

1. Create Azure App Service Plans with Azure App Services in East US and Central US
2. Build highly available load balancer infrastructure using Traffic Manager with Performance routing
3. Create Azure Key Vault service
4. Create Azure SQL Database in West US
5. Store SQL connection string in Azure Key Vault
6. Configure web apps to access Key Vault using managed identities

## Step 1: Create Resource Groups

1. Go to the [Azure Portal](https://portal.azure.com)
2. Search for "Resource groups" and click "Create"
3. Create three resource groups:
   - Name: `EastUSResourceGroup`, Region: East US
   - Name: `CentralUSResourceGroup`, Region: Central US
   - Name: `WestUSResourceGroup`, Region: West US

## Step 2: Create App Service Plans

1. Search for "App Service Plans" and click "Create"
2. Create first App Service Plan:
   - Resource Group: `EastUSResourceGroup`
   - Name: `EastUSAppServicePlan`
   - Operating System: Windows
   - Region: East US
   - Pricing Plan: Standard S1
3. Create second App Service Plan:
   - Resource Group: `CentralUSResourceGroup`
   - Name: `CentralUSAppServicePlan`
   - Operating System: Windows
   - Region: Central US
   - Pricing Plan: Standard S1

## Step 3: Create Web Apps

1. Search for "App Services" and click "Create"
2. Create first Web App:
   - Resource Group: `EastUSResourceGroup`
   - Name: `EastUSWebApp` (must be globally unique, add a suffix if needed)
   - Publish: Code
   - Runtime stack: Node 16 LTS
   - Operating System: Windows
   - Region: East US
   - App Service Plan: `EastUSAppServicePlan`
3. Create second Web App:
   - Resource Group: `CentralUSResourceGroup`
   - Name: `CentralUSWebApp` (must be globally unique, add a suffix if needed)
   - Publish: Code
   - Runtime stack: Node 16 LTS
   - Operating System: Windows
   - Region: Central US
   - App Service Plan: `CentralUSAppServicePlan`

## Step 4: Enable Managed Identity for Web Apps

1. Go to each Web App
2. Navigate to "Identity" in the left menu
3. Under "System assigned" tab, set Status to "On" and save
4. Note the Object ID for each web app (you'll need these later)

## Step 5: Create Azure Key Vault

1. Search for "Key vaults" and click "Create"
2. Basic settings:
   - Resource Group: `EastUSResourceGroup`
   - Key vault name: `MyKeyVault` (must be globally unique, add a suffix if needed)
   - Region: East US
   - Pricing tier: Standard
3. Access policy settings:
   - Permission model: Vault access policy
   - Access policies: Keep default for now (we'll add policies later)

## Step 6: Create SQL Server and Database

1. Search for "SQL databases" and click "Create"
2. Basic settings:
   - Resource Group: `WestUSResourceGroup`
   - Database name: `myDatabase`
   - Server: Create new
     - Server name: `sqlserver` (must be globally unique, add a suffix if needed)
     - Location: West US
     - Authentication method: SQL authentication
     - Server admin login: `sqladmin`
     - Password: Create a strong password and note it down
3. Compute + storage: Standard S0
4. After creation, go to the SQL server
5. Navigate to "Networking" in the left menu
6. Under "Firewall rules", enable "Allow Azure services and resources to access this server"

## Step 7: Store Connection String in Key Vault

1. Go to your Key Vault
2. Navigate to "Secrets" in the left menu
3. Click "Generate/Import"
4. Create a secret:
   - Name: `name_surname_1`
   - Value: `Server=tcp:<your-server-name>.database.windows.net,1433;Initial Catalog=myDatabase;Persist Security Info=False;User ID=sqladmin;Password=<your-password>;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;`
   - Replace `<your-server-name>` and `<your-password>` with your actual values

## Step 8: Configure Key Vault Access Policies

1. Go to your Key Vault
2. Navigate to "Access policies" in the left menu
3. Click "Create"
4. For the first Web App:
   - Select principal: Search for the Object ID of your East US Web App
   - Secret permissions: Select "Get" and "List"
   - Click "Add"
5. Repeat for the second Web App:
   - Select principal: Search for the Object ID of your Central US Web App
   - Secret permissions: Select "Get" and "List"
   - Click "Add"
6. Click "Save" to apply the policies

## Step 9: Configure Web Apps to Use Key Vault

1. Go to your East US Web App
2. Navigate to "Configuration" in the left menu
3. Under "Application settings", click "New application setting"
   - Name: `ConnectionString`
   - Value: `@Microsoft.KeyVault(VaultName=<your-key-vault-name>;SecretName=name_surname_1;SecretVersion=)`
   - Replace `<your-key-vault-name>` with your actual Key Vault name
4. Click "OK" and then "Save"
5. Repeat the same steps for your Central US Web App

## Step 10: Create Traffic Manager Profile

1. Search for "Traffic Manager profiles" and click "Create"
2. Basic settings:
   - Name: `MyTrafficManager` (must be globally unique, add a suffix if needed)
   - Routing method: Performance
   - Resource Group: `EastUSResourceGroup`
3. After creation, go to the Traffic Manager profile
4. Navigate to "Endpoints" in the left menu
5. Click "Add"
   - Type: Azure endpoint
   - Name: `EastUSEndpoint`
   - Target resource type: App Service
   - Target resource: Select your East US Web App
   - Click "Add"
6. Click "Add" again
   - Type: Azure endpoint
   - Name: `CentralUSEndpoint`
   - Target resource type: App Service
   - Target resource: Select your Central US Web App
   - Click "Add"

## Step 11: Create Database Table

1. Go to your SQL database
2. Click on "Query editor" in the left menu
3. Login with your SQL server credentials
4. Execute the following SQL script:

```sql
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
ELSE
BEGIN
    -- Check if table is empty
    IF (SELECT COUNT(*) FROM Items) = 0
    BEGIN
        -- Insert sample data
        INSERT INTO Items (name, description, createdAt)
        VALUES 
            ('Sample Item 1', 'This is a sample item for demonstration', GETDATE()),
            ('Sample Item 2', 'Another example item to show CRUD functionality', GETDATE()),
            ('Sample Item 3', 'A third item to populate the initial view', GETDATE());
    END
END

-- Verify data
SELECT * FROM Items;
```

## Step 12: Deploy the Application

1. Create a ZIP file containing:
   - `server.js`
   - `package.json`
   - `public/` directory

2. Go to your East US Web App
   - Navigate to "Deployment Center" in the left menu
   - Choose "ZIP Deploy" option
   - Upload your ZIP file
   
3. Repeat for your Central US Web App

## Step 13: Test the Application

1. Access your application through the direct Web App URLs:
   - `https://<your-east-us-webapp-name>.azurewebsites.net`
   - `https://<your-central-us-webapp-name>.azurewebsites.net`

2. Access your application through the Traffic Manager URL:
   - `https://<your-traffic-manager-name>.trafficmanager.net`

3. Verify that the CRUD operations work correctly

## Troubleshooting

If you encounter issues:

1. Check Web App logs:
   - Go to each Web App
   - Navigate to "Log stream" in the left menu

2. Verify Key Vault access:
   - Check that managed identities are enabled
   - Verify access policies are correctly set up

3. Check database connectivity:
   - Verify firewall rules allow Azure services
   - Check that the connection string is correct
