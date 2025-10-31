#!/bin/bash

RESOURCE_GROUP_EAST="EastUSResourceGroup"

# Auto-detect web app name
WEBAPP_EAST=$(az webapp list --resource-group $RESOURCE_GROUP_EAST --query "[0].name" -o tsv)

if [ -z "$WEBAPP_EAST" ]; then
    echo "Error: Could not find web app in $RESOURCE_GROUP_EAST"
    exit 1
fi

echo "Checking status of: $WEBAPP_EAST"
echo ""

# Check web app state
echo "1. Web App State:"
az webapp show --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query "{state:state,defaultHostName:defaultHostName}" -o table

echo ""
echo "2. Application Settings:"
az webapp config appsettings list --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query "[?name=='ConnectionString' || name=='WEBSITE_NODE_DEFAULT_VERSION' || name=='SCM_DO_BUILD_DURING_DEPLOYMENT'].{name:name,value:value}" -o table

echo ""
echo "3. Latest Deployment:"
az webapp deployment list --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST --query "[0].{status:status,message:message,deployer:deployer,received_time:received_time}" -o table

echo ""
echo "4. View logs with:"
echo "az webapp log tail --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST"
echo ""
echo "5. Test endpoints:"
echo "https://$WEBAPP_EAST.azurewebsites.net/test"
echo "https://$WEBAPP_EAST.azurewebsites.net/api/health"
