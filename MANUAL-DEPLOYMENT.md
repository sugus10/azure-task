# Manual Deployment Guide

Since your infrastructure is ready, here's how to manually deploy the application through the Azure Portal:

## Step 1: Prepare the Deployment Package

1. Create a ZIP file containing:
   - `server.js`
   - `package.json`
   - `public/` directory (with all files inside)
   - `.deployment` file (optional but recommended)

2. Make sure the ZIP file structure looks like this:
   ```
   deployment.zip
   ├── server.js
   ├── package.json
   ├── .deployment
   └── public/
       ├── index.html
       ├── app.js
       └── styles.css
   ```

## Step 2: Deploy via Azure Portal

### Option A: Using Deployment Center (Recommended)

1. Go to the Azure Portal
2. Navigate to your Web App (e.g., `EastUSWebApp1761914463`)
3. Click on "Deployment Center" in the left menu
4. Click on "Local Git" or "Zip Deploy"
5. If using Zip Deploy:
   - Click "Browse" and select your ZIP file
   - Click "Deploy"
6. Wait for deployment to complete (this will automatically run `npm install`)

### Option B: Using Advanced Tools (Kudu)

1. Go to: `https://<your-webapp-name>.scm.azurewebsites.net`
2. Click on "Debug Console" > "CMD" or "PowerShell"
3. Navigate to `site/wwwroot`
4. Upload your files or use the "Drag and drop" area
5. Run `npm install` in the console
6. Restart the web app

### Option C: Using Azure CLI (Automated)

Run this command:
```bash
./redeploy.sh
```

## Step 3: Verify Application Settings

Make sure these settings are configured in both web apps:

1. Go to Configuration > Application settings
2. Verify these settings exist:
   - `ConnectionString`: `@Microsoft.KeyVault(VaultName=MyKeyVault1761914463;SecretName=namesurname1;SecretVersion=)`
   - `WEBSITE_NODE_DEFAULT_VERSION`: `~16`
   - `SCM_DO_BUILD_DURING_DEPLOYMENT`: `true`

## Step 4: Verify Database Table

1. Go to SQL Database (`myDatabase` on server `sqlserver1761914463`)
2. Open Query Editor
3. Login with: `sqladmin` / `P@ssw0rd1761914463`
4. Run the SQL script from `simple-db-setup.sql` to create the Items table

## Step 5: Test the Application

1. Test the health endpoint:
   ```
   https://EastUSWebApp1761914463.azurewebsites.net/api/health
   ```

2. Test the simple endpoint:
   ```
   https://EastUSWebApp1761914463.azurewebsites.net/test
   ```

3. Test the main application:
   ```
   https://EastUSWebApp1761914463.azurewebsites.net
   ```

## Troubleshooting

### If you see 404 errors:
- Check if the application is running
- Verify npm install completed successfully
- Check the deployment logs

### If you see 500 errors:
- Check the application logs
- Verify the database connection string is resolving from Key Vault
- Check if the database table exists

### If you see "Connection string missing":
- Verify Key Vault access policies are set correctly
- Check that managed identity is enabled on the web app
- Verify the ConnectionString application setting is correct

### Network Security Groups:
- Azure App Service doesn't require NSG configuration for basic access
- Make sure SQL Server firewall allows Azure services (already configured)
- Key Vault should be accessible from the web app (already configured)

## Quick Commands

```bash
# Check web app status
az webapp show --name EastUSWebApp1761914463 --resource-group EastUSResourceGroup --query state

# View logs
az webapp log tail --name EastUSWebApp1761914463 --resource-group EastUSResourceGroup

# Restart web app
az webapp restart --name EastUSWebApp1761914463 --resource-group EastUSResourceGroup

# Check application settings
az webapp config appsettings list --name EastUSWebApp1761914463 --resource-group EastUSResourceGroup
```
