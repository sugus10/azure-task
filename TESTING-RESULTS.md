# Testing Results - What You Need to Show

## ✅ Task Requirements

1. **Two Azure App Services** in different regions
2. **Traffic Manager profile** with both web apps as endpoints
3. **Web app takes variable from Key Vault** (connection string)

---

## ✅ Test 1: Traffic Manager Configuration

### Command to Run:
```bash
az network traffic-manager endpoint list \
  -g EastUSResourceGroup \
  --profile-name myTrafficManager<TIMESTAMP>
```

### Expected Output - You MUST See:
```json
[
  {
    "endpointMonitorStatus": "Online",
    "endpointStatus": "Enabled",
    "name": "EastUSEndpoint",
    ...
  },
  {
    "endpointMonitorStatus": "Online",
    "endpointStatus": "Enabled",
    "name": "CentralUSEndpoint",
    ...
  }
]
```

**Key Requirements:**
- ✅ `endpointMonitorStatus`: **"Online"** (not "Degraded" or "Disabled")
- ✅ `endpointStatus`: **"Enabled"** (not "Disabled")
- ✅ Both endpoints listed (East US and Central US)

### OR Check in Azure Portal:
1. Go to Traffic Manager profile
2. Click **"Overview"** or **"Endpoints"**
3. Screenshot should show:
   - Both endpoints with status: **"Online"** ✓
   - Both endpoints: **"Enabled"** ✓

---

## ✅ Test 2: Web App Key Vault Configuration

### Command to Run:
```bash
# For East US Web App
az webapp config appsettings list \
  --name EastUSWebApp<TIMESTAMP> \
  --resource-group EastUSResourceGroup

# For Central US Web App
az webapp config appsettings list \
  --name CentralUSWebApp<TIMESTAMP> \
  --resource-group CentralUSResourceGroup
```

### Expected Output - You MUST See:
```json
[
  {
    "name": "ConnectionString",
    "slotSetting": false,
    "value": "@Microsoft.KeyVault(VaultName=MyKeyVault<TIMESTAMP>;SecretName=namesurname1;SecretVersion=)"
  },
  ...
]
```

**Key Requirements:**
- ✅ Setting name: **"ConnectionString"**
- ✅ Value format: **`@Microsoft.KeyVault(VaultName=...;SecretName=namesurname1;SecretVersion=)`**
- ✅ Must be exactly this format (Key Vault reference, not actual connection string)

### OR Check in Azure Portal:
1. Go to Web App → **"Configuration"** → **"Application settings"**
2. Find **"ConnectionString"** setting
3. Screenshot should show:
   - Setting name: **ConnectionString**
   - Value field is **GREEN** ✓ (indicates Key Vault reference)
   - Value shows Key Vault reference format

---

## ✅ Verification Checklist

### 1. Traffic Manager Test:
- [ ] Run command: `az network traffic-manager endpoint list`
- [ ] Both endpoints show: `"endpointMonitorStatus": "Online"`
- [ ] Both endpoints show: `"endpointStatus": "Enabled"`
- [ ] Screenshot of command output OR portal showing endpoints are Online

### 2. Key Vault Test:
- [ ] Run command: `az webapp config appsettings list`
- [ ] Setting name: `"ConnectionString"`
- [ ] Value starts with: `"@Microsoft.KeyVault(...)"`
- [ ] Contains: `SecretName=namesurname1`
- [ ] Screenshot of command output OR portal showing green field

### 3. Additional Evidence (Optional but Recommended):
- [ ] Web app URLs are accessible
- [ ] Application works (shows items from database)
- [ ] Screenshot of working application

---

## 📋 Quick Test Script

Run these commands on your deployment machine after setup:

```bash
# Set your resource names (replace <TIMESTAMP> with actual value)
TM_PROFILE="myTrafficManager<TIMESTAMP>"
EAST_WEBAPP="EastUSWebApp<TIMESTAMP>"
CENTRAL_WEBAPP="CentralUSWebApp<TIMESTAMP>"
RESOURCE_GROUP="EastUSResourceGroup"

# Test 1: Traffic Manager
echo "=== Testing Traffic Manager ==="
az network traffic-manager endpoint list \
  -g $RESOURCE_GROUP \
  --profile-name $TM_PROFILE \
  --query "[].{name:name, status:endpointStatus, monitor:endpointMonitorStatus}" \
  -o table

# Test 2: East US Web App Key Vault Config
echo ""
echo "=== Testing East US Web App Key Vault Config ==="
az webapp config appsettings list \
  --name $EAST_WEBAPP \
  --resource-group $RESOURCE_GROUP \
  --query "[?name=='ConnectionString']" \
  -o table

# Test 3: Central US Web App Key Vault Config
echo ""
echo "=== Testing Central US Web App Key Vault Config ==="
az webapp config appsettings list \
  --name $CENTRAL_WEBAPP \
  --resource-group CentralUSResourceGroup \
  --query "[?name=='ConnectionString']" \
  -o table
```

---

## 🎯 What to Submit

### Minimum Required:
1. **Screenshot/Output of Traffic Manager test:**
   - Shows both endpoints with `"endpointMonitorStatus": "Online"`
   - Shows both endpoints with `"endpointStatus": "Enabled"`

2. **Screenshot/Output of Key Vault test:**
   - Shows `ConnectionString` setting
   - Shows value: `@Microsoft.KeyVault(VaultName=...;SecretName=namesurname1;SecretVersion=)`
   - In portal: Shows green field

### Recommended Additional:
- Screenshot of working application
- Resource names list
- URLs for all services

---

## ⚠️ Common Issues

### If Traffic Manager endpoints show "Degraded":
- Wait 5-10 minutes for health checks to complete
- Check web apps are running and responding
- Check firewall rules allow Traffic Manager probes

### If Key Vault setting is NOT green:
- Verify Managed Identity is enabled on web app
- Verify access policy in Key Vault grants permissions to managed identity
- Check that setting value uses exact format: `@Microsoft.KeyVault(...)`

### If ConnectionString shows actual value instead of reference:
- Delete the setting and recreate it with Key Vault reference format
- Do NOT use the actual connection string value

---

## 📝 Summary

**To complete the task, you need:**

1. ✅ **Traffic Manager**: Both endpoints Online and Enabled
2. ✅ **Key Vault Config**: ConnectionString setting with green Key Vault reference
3. ✅ **Screenshots/Output** proving both tests pass

**The tests verify:**
- Traffic Manager is properly routing traffic
- Web apps are securely accessing secrets from Key Vault
- No hardcoded credentials in application

