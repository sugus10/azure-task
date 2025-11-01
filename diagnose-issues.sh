#!/bin/bash

# Diagnostic script to check for common deployment issues

RESOURCE_GROUP_EAST="EastUSResourceGroup"
RESOURCE_GROUP_CENTRAL="CentralUSResourceGroup"

# Auto-detect web app names
WEBAPP_EAST=$(az webapp list --resource-group $RESOURCE_GROUP_EAST --query "[0].name" -o tsv)
WEBAPP_CENTRAL=$(az webapp list --resource-group $RESOURCE_GROUP_CENTRAL --query "[0].name" -o tsv)

if [ -z "$WEBAPP_EAST" ]; then
    echo "Error: Could not find web app in $RESOURCE_GROUP_EAST"
    exit 1
fi

echo "=========================================="
echo "Diagnostic Check for: $WEBAPP_EAST"
echo "=========================================="
echo ""

# 1. Check web app state
echo "1. Web App State:"
STATE=$(az webapp show --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query state -o tsv)
echo "   State: $STATE"
if [ "$STATE" != "Running" ]; then
    echo "   ⚠️  WARNING: Web app is not in Running state!"
fi
echo ""

# 2. Check application settings
echo "2. Application Settings:"
echo ""
NODE_VERSION=$(az webapp config appsettings list --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query "[?name=='WEBSITE_NODE_DEFAULT_VERSION'].value" -o tsv)
SCM_BUILD=$(az webapp config appsettings list --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query "[?name=='SCM_DO_BUILD_DURING_DEPLOYMENT'].value" -o tsv)
CONN_STRING=$(az webapp config appsettings list --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query "[?name=='ConnectionString'].value" -o tsv)

echo "   WEBSITE_NODE_DEFAULT_VERSION: ${NODE_VERSION:-MISSING}"
if [ -z "$NODE_VERSION" ]; then
    echo "   ⚠️  WARNING: Node.js version not set!"
fi

echo "   SCM_DO_BUILD_DURING_DEPLOYMENT: ${SCM_BUILD:-MISSING}"
if [ "$SCM_BUILD" != "true" ]; then
    echo "   ⚠️  WARNING: Build during deployment not enabled!"
fi

if [ -n "$CONN_STRING" ]; then
    if [[ "$CONN_STRING" == *"@Microsoft.KeyVault"* ]]; then
        echo "   ConnectionString: Present (Key Vault reference)"
    else
        echo "   ConnectionString: Present (direct value)"
    fi
else
    echo "   ConnectionString: MISSING"
    echo "   ⚠️  WARNING: Connection string not configured!"
fi
echo ""

# 3. Check startup command
echo "3. Startup Configuration:"
STARTUP_CMD=$(az webapp config show --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query "appCommandLine" -o tsv)
ALWAYS_ON=$(az webapp config show --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query "alwaysOn" -o tsv)

echo "   Startup Command: ${STARTUP_CMD:-MISSING}"
if [ -z "$STARTUP_CMD" ]; then
    echo "   ⚠️  WARNING: Startup command not configured!"
    echo "   This is likely why you see a static website!"
fi

echo "   Always On: ${ALWAYS_ON:-false}"
if [ "$ALWAYS_ON" != "true" ]; then
    echo "   ⚠️  WARNING: Always On is disabled!"
fi
echo ""

# 4. Check latest deployment
echo "4. Latest Deployment:"
DEPLOYMENT=$(az webapp deployment list --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query "[0].{status:status,message:message,received_time:received_time}" -o tsv 2>/dev/null)
if [ -n "$DEPLOYMENT" ]; then
    echo "   $DEPLOYMENT"
else
    echo "   No deployments found"
    echo "   ⚠️  WARNING: Application code may not be deployed!"
fi
echo ""

# 5. Check if files exist in wwwroot
echo "5. Checking deployed files (via Kudu API):"
echo "   Checking if server.js exists..."
# Note: This requires Kudu API access, which may need authentication
echo "   (Run 'az webapp log tail' to see actual file structure)"
echo ""

# 6. Test endpoints
echo "6. Testing Endpoints:"
echo ""
echo "   Testing /api/health endpoint..."
HEALTH_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://$WEBAPP_EAST.azurewebsites.net/api/health" 2>/dev/null || echo "000")
if [ "$HEALTH_RESPONSE" = "200" ]; then
    echo "   ✓ Health endpoint responding (200 OK)"
elif [ "$HEALTH_RESPONSE" = "000" ]; then
    echo "   ⚠️  Health endpoint: Connection failed"
else
    echo "   ⚠️  Health endpoint: HTTP $HEALTH_RESPONSE"
fi

echo ""
echo "   Testing root endpoint..."
ROOT_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://$WEBAPP_EAST.azurewebsites.net/" 2>/dev/null || echo "000")
if [ "$ROOT_RESPONSE" = "200" ]; then
    echo "   ✓ Root endpoint responding (200 OK)"
elif [ "$ROOT_RESPONSE" = "402" ] || [ "$ROOT_RESPONSE" = "502" ] || [ "$ROOT_RESPONSE" = "503" ]; then
    echo "   ⚠️  Root endpoint: HTTP $ROOT_RESPONSE (App may not be running)"
else
    echo "   ⚠️  Root endpoint: HTTP $ROOT_RESPONSE"
fi
echo ""

# Summary
echo "=========================================="
echo "Summary & Recommendations:"
echo "=========================================="
ISSUES=0

if [ "$STATE" != "Running" ]; then
    echo "  [ISSUE] Web app is not running"
    ISSUES=$((ISSUES + 1))
fi

if [ -z "$NODE_VERSION" ]; then
    echo "  [ISSUE] Node.js version not configured"
    ISSUES=$((ISSUES + 1))
fi

if [ "$SCM_BUILD" != "true" ]; then
    echo "  [ISSUE] Build during deployment disabled"
    ISSUES=$((ISSUES + 1))
fi

if [ -z "$STARTUP_CMD" ]; then
    echo "  [CRITICAL] Startup command missing - This is likely the main issue!"
    ISSUES=$((ISSUES + 1))
fi

if [ -z "$CONN_STRING" ]; then
    echo "  [ISSUE] Connection string missing"
    ISSUES=$((ISSUES + 1))
fi

if [ "$ROOT_RESPONSE" != "200" ]; then
    echo "  [ISSUE] Application not responding correctly"
    ISSUES=$((ISSUES + 1))
fi

if [ $ISSUES -eq 0 ]; then
    echo "  ✓ No obvious issues found"
    echo ""
    echo "  If problems persist, check logs:"
    echo "    az webapp log tail --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST"
else
    echo ""
    echo "  Found $ISSUES issue(s). Run ./fix-deployment.sh to fix them automatically."
fi
echo ""

