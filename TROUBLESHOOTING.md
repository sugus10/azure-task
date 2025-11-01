# Troubleshooting Guide: 402 Error and Static Website Issues

## Problem Description

When deploying the Azure infrastructure, you may encounter:
- **402 HTTP Error** (or 502/503 errors)
- **Static website** being displayed instead of your Node.js application
- Application not responding at all

## Root Causes

The main issues are:

1. **Missing Startup Command** - Azure doesn't know how to start your Node.js application
2. **Missing Build Configuration** - `npm install` may not run during deployment
3. **Application Not Deployed** - Code may not be properly deployed
4. **Application Crashed** - Node.js app may be failing to start due to configuration issues

## Quick Fix (For Existing Deployments)

If your infrastructure is already deployed, run:

```bash
./fix-deployment.sh
```

This script will:
- ✅ Fix all application settings
- ✅ Configure startup command
- ✅ Redeploy your application
- ✅ Restart the web apps

## Diagnostic Check

To diagnose issues with your current deployment:

```bash
./diagnose-issues.sh
```

This will check:
- Web app state
- Application settings
- Startup configuration
- Deployment status
- Endpoint responses

## Manual Fix Steps

If you prefer to fix manually:

### 1. Fix Application Settings

```bash
# Set resource group and web app name
RESOURCE_GROUP_EAST="EastUSResourceGroup"
WEBAPP_EAST=$(az webapp list --resource-group $RESOURCE_GROUP_EAST --query "[0].name" -o tsv)

# Fix settings
az webapp config appsettings set \
  --name $WEBAPP_EAST \
  --resource-group $RESOURCE_GROUP_EAST \
  --settings \
    SCM_DO_BUILD_DURING_DEPLOYMENT=true \
    WEBSITE_NODE_DEFAULT_VERSION="~16"
```

### 2. Configure Startup Command

```bash
az webapp config set \
  --name $WEBAPP_EAST \
  --resource-group $RESOURCE_GROUP_EAST \
  --startup-file "npm start" \
  --always-on true
```

### 3. Redeploy Application

```bash
# Create deployment package
zip -r deployment.zip server.js package.json public/ .deployment

# Deploy
az webapp deployment source config-zip \
  --resource-group $RESOURCE_GROUP_EAST \
  --name $WEBAPP_EAST \
  --src deployment.zip

# Restart
az webapp restart \
  --name $WEBAPP_EAST \
  --resource-group $RESOURCE_GROUP_EAST
```

## Verification

After fixing, verify the deployment:

### 1. Check Application Settings
```bash
az webapp config appsettings list \
  --name $WEBAPP_EAST \
  --resource-group $RESOURCE_GROUP_EAST
```

Should show:
- `WEBSITE_NODE_DEFAULT_VERSION`: `~16`
- `SCM_DO_BUILD_DURING_DEPLOYMENT`: `true`
- `ConnectionString`: Key Vault reference

### 2. Check Startup Command
```bash
az webapp config show \
  --name $WEBAPP_EAST \
  --resource-group $RESOURCE_GROUP_EAST \
  --query "appCommandLine"
```

Should show: `npm start`

### 3. Check Logs
```bash
az webapp log tail \
  --name $WEBAPP_EAST \
  --resource-group $RESOURCE_GROUP_EAST
```

Look for:
- ✅ "Server running on port..."
- ✅ "Database connection pool established..."
- ❌ Any error messages

### 4. Test Endpoints
```bash
# Health check
curl https://$WEBAPP_EAST.azurewebsites.net/api/health

# Root endpoint
curl https://$WEBAPP_EAST.azurewebsites.net/
```

## Common Error Messages

### "Connection string missing"
- **Cause**: Key Vault reference not resolving
- **Fix**: Check managed identity permissions on Key Vault

### "Cannot find module 'express'"
- **Cause**: `npm install` didn't run
- **Fix**: Ensure `SCM_DO_BUILD_DURING_DEPLOYMENT=true` is set

### "EADDRINUSE" or "Port already in use"
- **Cause**: Multiple Node.js processes running
- **Fix**: Restart the web app

### "ECONNREFUSED" (Database connection)
- **Cause**: SQL Server firewall rules or connection string issue
- **Fix**: Verify SQL firewall allows Azure services, check connection string in Key Vault

## What Was Fixed in azure-setup.sh

The setup script has been updated to:
1. ✅ Set `SCM_DO_BUILD_DURING_DEPLOYMENT=true` during initial setup
2. ✅ Configure startup command (`npm start`) for both web apps
3. ✅ Enable "Always On" to prevent app from going idle
4. ✅ Include `.deployment` file in deployment package
5. ✅ Wait and restart web apps after deployment

## Prevention

For future deployments, ensure:
1. Always run `./azure-setup.sh` (updated version) for fresh deployments
2. Use `./redeploy.sh` for code updates
3. Run `./diagnose-issues.sh` if you encounter problems
4. Check logs immediately after deployment

## Still Having Issues?

1. Check the diagnostic output: `./diagnose-issues.sh`
2. Review application logs: `az webapp log tail`
3. Verify database table exists (run `simple-db-setup.sql`)
4. Check Key Vault access policies
5. Verify managed identity is enabled on web apps

