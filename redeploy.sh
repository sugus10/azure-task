#!/bin/bash

# Variables
RESOURCE_GROUP_EAST="EastUSResourceGroup"
RESOURCE_GROUP_CENTRAL="CentralUSResourceGroup"

# Auto-detect web app names
echo "Detecting web app names..."
WEBAPP_EAST=$(az webapp list --resource-group $RESOURCE_GROUP_EAST --query "[0].name" -o tsv)
WEBAPP_CENTRAL=$(az webapp list --resource-group $RESOURCE_GROUP_CENTRAL --query "[0].name" -o tsv)

if [ -z "$WEBAPP_EAST" ] || [ -z "$WEBAPP_CENTRAL" ]; then
    echo "Error: Could not detect web app names. Please check resource groups."
    exit 1
fi

echo "Found Web Apps:"
echo "  East US: $WEBAPP_EAST"
echo "  Central US: $WEBAPP_CENTRAL"
echo ""

echo "Redeploying application with connection string fix..."

# Create deployment package (without web.config - Azure handles Node.js apps automatically)
echo "Creating deployment package..."

# Remove old deployment zip if exists
rm -f deployment.zip 2>/dev/null || del deployment.zip 2>nul || true

if command -v zip &> /dev/null; then
    if [ -f .deployment ]; then
        zip -r deployment.zip server.js package.json public/ .deployment -x "*.git*" "node_modules/*"
    else
        zip -r deployment.zip server.js package.json public/ -x "*.git*" "node_modules/*"
    fi
else
    echo "zip command not found, using PowerShell instead..."
    echo "Using dedicated PowerShell script to ensure proper folder structure..."
    
    # Check if we have the PowerShell script, if not, use inline script
    if [ -f create-deployment-zip.ps1 ]; then
        powershell -ExecutionPolicy Bypass -File create-deployment-zip.ps1
    else
        # Inline PowerShell script that properly preserves folder structure
        echo "Creating zip with inline PowerShell script..."
        powershell -ExecutionPolicy Bypass -Command "\
            if (Test-Path deployment.zip) { Remove-Item deployment.zip -Force }; \
            \$tempDir = Join-Path \$env:TEMP \"deployment-$(Get-Random)\"; \
            New-Item -ItemType Directory -Path \$tempDir -Force | Out-Null; \
            Copy-Item -Path server.js,package.json,public -Destination \$tempDir -Recurse -Force; \
            if (Test-Path .deployment) { Copy-Item -Path .deployment -Destination \$tempDir -Force }; \
            Compress-Archive -Path \"\$tempDir\*\" -DestinationPath deployment.zip -Force; \
            Write-Host '✓ Deployment package created'; \
            \$verify = Join-Path \$env:TEMP \"verify-$(Get-Random)\"; \
            Expand-Archive -Path deployment.zip -DestinationPath \$verify -Force; \
            if (Test-Path \"\$verify\public\index.html\") { Write-Host '✓ Structure verified: public/index.html exists' } else { Write-Host '✗ ERROR: Structure incorrect!' }; \
            Remove-Item -Recurse -Force \$verify,\$tempDir"
    fi
fi

echo "Deployment package created. Verifying structure..."
if command -v unzip &> /dev/null; then
    echo "Package contents:"
    unzip -l deployment.zip | grep -E "public/|index.html|server.js|package.json" || echo "WARNING: public folder might not be included correctly"
    echo ""
    echo "Checking for public/index.html in package:"
    unzip -l deployment.zip | grep "public/index.html" && echo "✓ public/index.html found" || echo "✗ WARNING: public/index.html NOT found in package!"
elif command -v powershell &> /dev/null; then
    echo "Verifying package structure with PowerShell:"
    powershell -Command "\$temp = 'temp-check-$(Get-Random)'; Expand-Archive -Path deployment.zip -DestinationPath \$temp -Force; if (Test-Path \"\$temp\\public\\index.html\") { Write-Host '✓ public/index.html found in package' } else { Write-Host '✗ WARNING: public/index.html NOT found in package!'; Get-ChildItem -Recurse \$temp | Select-Object FullName }; Remove-Item -Recurse -Force \$temp" 2>/dev/null || echo "Could not verify package structure"
fi

# Ensure configuration is correct before deployment
echo "Configuring web apps..."
az webapp config set --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --startup-file "npm start" --always-on true
az webapp config set --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL --startup-file "npm start" --always-on true

az webapp config appsettings set --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST \
  --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true WEBSITE_NODE_DEFAULT_VERSION="~16" --output none

az webapp config appsettings set --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL \
  --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true WEBSITE_NODE_DEFAULT_VERSION="~16" --output none

# Deploy to both web apps
echo "Deploying to East US Web App..."
az webapp deployment source config-zip --resource-group $RESOURCE_GROUP_EAST --name $WEBAPP_EAST --src deployment.zip

echo "Deploying to Central US Web App..."
az webapp deployment source config-zip --resource-group $RESOURCE_GROUP_CENTRAL --name $WEBAPP_CENTRAL --src deployment.zip

# Wait a bit for deployment to process
echo "Waiting for deployment to process..."
sleep 10

# Restart web apps to ensure they pick up changes
echo "Restarting web apps..."
az webapp restart --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST
az webapp restart --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL

echo ""
echo "Deployment completed! Wait about 30 seconds and then check:"
echo "https://$WEBAPP_EAST.azurewebsites.net"
echo ""
echo "To check logs if there are still issues:"
echo "az webapp log tail --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST"
