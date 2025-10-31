#!/bin/bash

WEBAPP_EAST="EastUSWebApp1761914463"
WEBAPP_CENTRAL="CentralUSWebApp1761914463"
RESOURCE_GROUP_EAST="EastUSResourceGroup"
RESOURCE_GROUP_CENTRAL="CentralUSResourceGroup"

echo "Enabling detailed logging for web apps..."

# Enable application logging
az webapp log config --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST \
  --application-logging filesystem \
  --detailed-error-messages true \
  --failed-request-tracing true \
  --web-server-logging filesystem

az webapp log config --name $WEBAPP_CENTRAL --resource-group $RESOURCE_GROUP_CENTRAL \
  --application-logging filesystem \
  --detailed-error-messages true \
  --failed-request-tracing true \
  --web-server-logging filesystem

echo "Logging enabled. Now restart the web apps and check the logs again."
echo "To view logs:"
echo "az webapp log tail --name $WEBAPP_EAST --resource-group $RESOURCE_GROUP_EAST"
