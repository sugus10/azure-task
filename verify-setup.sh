#!/bin/bash

# Quick verification script to check if everything is set up correctly

WEBAPP_EAST="EastUSWebApp1761914463"
RESOURCE_GROUP_EAST="EastUSResourceGroup"

echo "Verifying Azure infrastructure setup..."
echo ""

# Check web app status
echo "1. Web App Status:"
STATE=$(az webapp show --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query state -o tsv)
echo "   State: $STATE"
if [ "$STATE" == "Running" ]; then
    echo "   ✓ Web App is running"
else
    echo "   ✗ Web App is not running"
fi

# Check managed identity
echo ""
echo "2. Managed Identity:"
IDENTITY=$(az webapp identity show --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query principalId -o tsv)
if [ ! -z "$IDENTITY" ]; then
    echo "   ✓ Managed Identity enabled: $IDENTITY"
else
    echo "   ✗ Managed Identity not enabled"
fi

# Check ConnectionString setting
echo ""
echo "3. ConnectionString Setting:"
CONN_STR=$(az webapp config appsettings list --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query "[?name=='ConnectionString'].value" -o tsv)
if [ ! -z "$CONN_STR" ]; then
    echo "   ✓ ConnectionString is set"
    if [[ "$CONN_STR" == *"@Microsoft.KeyVault"* ]]; then
        echo "   ✓ Key Vault reference detected"
    else
        echo "   ⚠ ConnectionString doesn't look like a Key Vault reference"
    fi
else
    echo "   ✗ ConnectionString is not set"
fi

# Check Node.js version
echo ""
echo "4. Node.js Version:"
NODE_VERSION=$(az webapp config appsettings list --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query "[?name=='WEBSITE_NODE_DEFAULT_VERSION'].value" -o tsv)
if [ ! -z "$NODE_VERSION" ]; then
    echo "   ✓ Node.js version: $NODE_VERSION"
else
    echo "   ⚠ Node.js version not explicitly set"
fi

echo ""
echo "5. Test URLs:"
echo "   Health check: https://$WEBAPP_EAST.azurewebsites.net/api/health"
echo "   Test endpoint: https://$WEBAPP_EAST.azurewebsites.net/test"
echo "   Main app: https://$WEBAPP_EAST.azurewebsites.net"

echo ""
echo "Verification complete!"
echo ""
echo "Next steps:"
echo "1. Make sure the database table is created (use Azure Portal Query Editor)"
echo "2. Deploy the application (use ./redeploy.sh or manual deployment)"
echo "3. Test the URLs above"
