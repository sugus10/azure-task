#!/bin/bash

# Script to verify task requirements are met
# This tests Traffic Manager and Key Vault configuration

RESOURCE_GROUP_EAST="EastUSResourceGroup"
RESOURCE_GROUP_CENTRAL="CentralUSResourceGroup"

# Auto-detect resource names
echo "Detecting resource names..."
TM_PROFILE=$(az network traffic-manager profile list --resource-group $RESOURCE_GROUP_EAST --query "[0].name" -o tsv)
EAST_WEBAPP=$(az webapp list --resource-group $RESOURCE_GROUP_EAST --query "[0].name" -o tsv)
CENTRAL_WEBAPP=$(az webapp list --resource-group $RESOURCE_GROUP_CENTRAL --query "[0].name" -o tsv)

if [ -z "$TM_PROFILE" ] || [ -z "$EAST_WEBAPP" ] || [ -z "$CENTRAL_WEBAPP" ]; then
    echo "Error: Could not detect all resource names"
    echo "Please ensure all resources are deployed first"
    exit 1
fi

echo "Found Resources:"
echo "  Traffic Manager: $TM_PROFILE"
echo "  East US Web App: $EAST_WEBAPP"
echo "  Central US Web App: $CENTRAL_WEBAPP"
echo ""

# Test 1: Traffic Manager Endpoints
echo "=========================================="
echo "TEST 1: Traffic Manager Configuration"
echo "=========================================="
echo ""
echo "Command: az network traffic-manager endpoint list -g $RESOURCE_GROUP_EAST --profile-name $TM_PROFILE"
echo ""

az network traffic-manager endpoint list \
  -g $RESOURCE_GROUP_EAST \
  --profile-name $TM_PROFILE \
  --query "[].{Name:name, Status:endpointStatus, Monitor:endpointMonitorStatus}" \
  -o table

echo ""
echo "Checking endpoint status..."

ENDPOINTS=$(az network traffic-manager endpoint list \
  -g $RESOURCE_GROUP_EAST \
  --profile-name $TM_PROFILE \
  --query "[].{status:endpointStatus, monitor:endpointMonitorStatus}" \
  -o tsv)

ALL_ONLINE=true
ALL_ENABLED=true

while IFS=$'\t' read -r status monitor; do
    if [ "$monitor" != "Online" ]; then
        ALL_ONLINE=false
        echo "⚠️  WARNING: Found endpoint with status: $monitor (should be Online)"
    fi
    if [ "$status" != "Enabled" ]; then
        ALL_ENABLED=false
        echo "⚠️  WARNING: Found endpoint with status: $status (should be Enabled)"
    fi
done <<< "$ENDPOINTS"

echo ""
if [ "$ALL_ONLINE" = true ] && [ "$ALL_ENABLED" = true ]; then
    echo "✅ PASS: All endpoints are Online and Enabled"
else
    echo "❌ FAIL: Some endpoints are not Online or not Enabled"
    echo ""
    echo "Full endpoint details:"
    az network traffic-manager endpoint list \
      -g $RESOURCE_GROUP_EAST \
      --profile-name $TM_PROFILE \
      -o table
fi

echo ""
echo "=========================================="
echo "TEST 2: East US Web App Key Vault Config"
echo "=========================================="
echo ""
echo "Command: az webapp config appsettings list --name $EAST_WEBAPP --resource-group $RESOURCE_GROUP_EAST"
echo ""

CONN_STRING=$(az webapp config appsettings list \
  --name $EAST_WEBAPP \
  --resource-group $RESOURCE_GROUP_EAST \
  --query "[?name=='ConnectionString'].value" \
  -o tsv)

if [ -z "$CONN_STRING" ]; then
    echo "❌ FAIL: ConnectionString setting not found!"
    echo ""
    echo "All settings:"
    az webapp config appsettings list \
      --name $EAST_WEBAPP \
      --resource-group $RESOURCE_GROUP_EAST \
      -o table
else
    echo "Found ConnectionString setting:"
    echo "$CONN_STRING"
    echo ""
    
    if [[ "$CONN_STRING" == *"@Microsoft.KeyVault"* ]]; then
        if [[ "$CONN_STRING" == *"SecretName=namesurname1"* ]]; then
            echo "✅ PASS: ConnectionString uses Key Vault reference"
            echo "   Format: Correct"
            echo "   Secret Name: namesurname1 ✓"
        else
            echo "⚠️  WARNING: Key Vault reference found but SecretName is not 'namesurname1'"
        fi
    else
        echo "❌ FAIL: ConnectionString does NOT use Key Vault reference"
        echo "   Current value appears to be hardcoded"
        echo "   Expected format: @Microsoft.KeyVault(VaultName=...;SecretName=namesurname1;SecretVersion=)"
    fi
fi

echo ""
echo "=========================================="
echo "TEST 3: Central US Web App Key Vault Config"
echo "=========================================="
echo ""
echo "Command: az webapp config appsettings list --name $CENTRAL_WEBAPP --resource-group $RESOURCE_GROUP_CENTRAL"
echo ""

CONN_STRING_CENTRAL=$(az webapp config appsettings list \
  --name $CENTRAL_WEBAPP \
  --resource-group $RESOURCE_GROUP_CENTRAL \
  --query "[?name=='ConnectionString'].value" \
  -o tsv)

if [ -z "$CONN_STRING_CENTRAL" ]; then
    echo "❌ FAIL: ConnectionString setting not found!"
else
    echo "Found ConnectionString setting:"
    echo "$CONN_STRING_CENTRAL"
    echo ""
    
    if [[ "$CONN_STRING_CENTRAL" == *"@Microsoft.KeyVault"* ]]; then
        if [[ "$CONN_STRING_CENTRAL" == *"SecretName=namesurname1"* ]]; then
            echo "✅ PASS: ConnectionString uses Key Vault reference"
            echo "   Format: Correct"
            echo "   Secret Name: namesurname1 ✓"
        else
            echo "⚠️  WARNING: Key Vault reference found but SecretName is not 'namesurname1'"
        fi
    else
        echo "❌ FAIL: ConnectionString does NOT use Key Vault reference"
        echo "   Current value appears to be hardcoded"
    fi
fi

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo "To submit your task, provide:"
echo "1. Screenshot/output of Traffic Manager test showing endpoints are Online and Enabled"
echo "2. Screenshot/output of Key Vault test showing ConnectionString with green field"
echo ""
echo "Resource Names for reference:"
echo "  Traffic Manager: $TM_PROFILE"
echo "  East US Web App: $EAST_WEBAPP"
echo "  Central US Web App: $CENTRAL_WEBAPP"
echo ""

