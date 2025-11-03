# Project Deliverables Checklist

## What You Need to Provide/Submit

### ✅ 1. Deployment Evidence

#### Screenshots/Documentation Needed:

**A. Resource Groups Created**
- [ ] Screenshot of 3 Resource Groups:
  - `EastUSResourceGroup`
  - `CentralUSResourceGroup`
  - `WestUSResourceGroup`

**B. App Service Plans**
- [ ] Screenshot showing 2 App Service Plans:
  - `EastUSAppServicePlan` in East US (S1 SKU)
  - `CentralUSAppServicePlan` in Central US (S1 SKU)

**C. Web Apps**
- [ ] Screenshot showing 2 Web Apps:
  - `EastUSWebApp<TIMESTAMP>` 
  - `CentralUSWebApp<TIMESTAMP>`
- [ ] Screenshot of web app configuration showing:
  - Always On: Enabled
  - Startup command: `npm start`
  - Node.js version: 16.x

**D. Traffic Manager**
- [ ] Screenshot of Traffic Manager profile:
  - Name: `myTrafficManager<TIMESTAMP>`
  - Routing method: Performance
  - Status: Enabled
- [ ] Screenshot showing 2 endpoints configured:
  - East US endpoint (Enabled)
  - Central US endpoint (Enabled)

**E. Azure Key Vault**
- [ ] Screenshot of Key Vault:
  - Name: `MyKeyVault<TIMESTAMP>`
  - Location: East US
- [ ] Screenshot of secret stored:
  - Secret name: `namesurname1`
  - Shows it contains SQL connection string

**F. Azure SQL Database**
- [ ] Screenshot of SQL Server:
  - Server name: `sqlserver<TIMESTAMP>`
  - Location: West US
- [ ] Screenshot of SQL Database:
  - Database name: `myDatabase`
  - Service tier: Standard S0
- [ ] Screenshot of Firewall rules:
  - Shows "AllowAzureServices" rule (0.0.0.0 - 0.0.0.0)

**G. Managed Identity**
- [ ] Screenshot showing Managed Identity enabled on both web apps
- [ ] Screenshot of Key Vault access policies:
  - Shows both web app managed identities have Get/List permissions

---

### ✅ 2. Working Application Evidence

#### Application URLs:
- [ ] **East US Web App URL**: 
  ```
  https://EastUSWebApp<TIMESTAMP>.azurewebsites.net
  ```
  
- [ ] **Central US Web App URL**: 
  ```
  https://CentralUSWebApp<TIMESTAMP>.azurewebsites.net
  ```

- [ ] **Traffic Manager URL**: 
  ```
  https://mytrafficmanager<TIMESTAMP>.trafficmanager.net
  ```

#### Screenshots Needed:
- [ ] **Homepage**: Screenshot of the CRUD application main page showing items
- [ ] **Create**: Screenshot of adding a new item
- [ ] **Read**: Screenshot showing list of items from database
- [ ] **Update**: Screenshot of editing an existing item
- [ ] **Delete**: Screenshot confirming item deletion
- [ ] **API Health Check**: Screenshot of `/api/health` endpoint response:
  ```json
  {
    "status": "ok",
    "timestamp": "...",
    "connectionString": "Present",
    "nodeVersion": "v16.x.x"
  }
  ```

---

### ✅ 3. Configuration Verification

#### Application Settings Screenshots:
- [ ] **East US Web App Configuration**:
  - `ConnectionString`: Shows Key Vault reference
    ```
    @Microsoft.KeyVault(VaultName=MyKeyVault<TIMESTAMP>;SecretName=namesurname1;SecretVersion=)
    ```
  - `WEBSITE_NODE_DEFAULT_VERSION`: `~16`
  - `SCM_DO_BUILD_DURING_DEPLOYMENT`: `true`
  
- [ ] **Central US Web App Configuration**: Same as above

#### Startup Configuration:
- [ ] Screenshot showing startup command: `npm start`
- [ ] Screenshot showing Always On: `true`

---

### ✅ 4. Database Evidence

#### SQL Database Table:
- [ ] Screenshot of Query Editor showing:
  - Table `Items` exists
  - Table structure:
    - id (INT, Primary Key, Identity)
    - name (NVARCHAR(100), NOT NULL)
    - description (NVARCHAR(500))
    - createdAt (DATETIME)
    - updatedAt (DATETIME)
  
- [ ] Screenshot showing sample data:
  ```sql
  SELECT * FROM Items;
  ```
  Should show at least 3 sample items

---

### ✅ 5. Testing Evidence

#### Functional Testing:
- [ ] **Create Item**: Video or screenshots showing:
  1. Click "Add New Item"
  2. Enter name and description
  3. Save
  4. Item appears in list

- [ ] **Read Items**: Screenshot showing:
  - List of all items displayed correctly
  - Items loaded from database

- [ ] **Update Item**: Video or screenshots showing:
  1. Click edit button on an item
  2. Modify name/description
  3. Save
  4. Changes reflected in list

- [ ] **Delete Item**: Video or screenshots showing:
  1. Click delete button
  2. Confirm deletion
  3. Item removed from list

#### API Testing:
- [ ] **GET /api/items**: Screenshot of API response showing JSON array of items
- [ ] **POST /api/items**: Screenshot of creating item via API (using Postman/curl)
- [ ] **PUT /api/items/:id**: Screenshot of updating item via API
- [ ] **DELETE /api/items/:id**: Screenshot of deleting item via API

---

### ✅ 6. Logs and Monitoring

#### Application Logs:
- [ ] Screenshot of Web App logs showing:
  - Application started successfully
  - Database connection established
  - No critical errors

#### Key Vault Access Logs:
- [ ] Screenshot showing managed identity successfully accessing Key Vault

---

### ✅ 7. Documentation

#### Required Documentation:
- [ ] **Architecture Diagram**: Visual representation of:
  - Traffic Manager
  - Two Web Apps
  - Key Vault
  - SQL Database
  - Data flow

- [ ] **Deployment Summary**: Document containing:
  - Resource names and IDs
  - URLs for all services
  - SQL credentials (for reference)
  - Any issues encountered and solutions

- [ ] **Configuration Summary**: Table listing:
  - All resource names
  - Resource groups
  - Locations
  - SKUs/Pricing tiers
  - Key configuration settings

---

### ✅ 8. Code Evidence

#### Source Code:
- [ ] **Repository Structure**: Screenshot or listing showing:
  ```
  ├── server.js
  ├── package.json
  ├── public/
  │   ├── index.html
  │   ├── app.js
  │   └── styles.css
  ├── azure-setup.sh
  ├── simple-db-setup.sql
  └── README.md
  ```

- [ ] **Key Code Files**: Evidence that:
  - `server.js` uses Key Vault connection string
  - `server.js` has all CRUD endpoints
  - Frontend calls API correctly

---

### ✅ 9. Performance/Routing Evidence

#### Traffic Manager Testing:
- [ ] Screenshot showing Traffic Manager endpoint health:
  - Both endpoints showing "Online" or "Degraded"
  - Latency metrics visible

- [ ] Test from different locations (if possible):
  - Document which endpoint Traffic Manager routes to
  - Show Performance routing working

---

### ✅ 10. Security Evidence

#### Managed Identity Verification:
- [ ] Screenshot showing:
  - Managed Identity enabled on web apps
  - Principal IDs visible

#### Key Vault Access:
- [ ] Screenshot of Key Vault access policies showing:
  - Both web app managed identities listed
  - Permissions: Get, List (for secrets)

#### Connection String Security:
- [ ] Screenshot confirming:
  - No connection strings hardcoded in application code
  - Connection string stored only in Key Vault
  - Application settings show Key Vault reference, not actual value

---

## Quick Submission Checklist

### Minimum Required:
- [ ] 2 Web Apps deployed and running
- [ ] Traffic Manager configured with 2 endpoints
- [ ] Key Vault created with secret stored
- [ ] SQL Database created with Items table
- [ ] Application accessible via all URLs
- [ ] CRUD operations working
- [ ] Managed Identity configured
- [ ] Screenshots of Azure Portal showing all resources

### Nice to Have:
- [ ] API testing evidence (Postman/curl)
- [ ] Architecture diagram
- [ ] Performance testing results
- [ ] Log analysis
- [ ] Code repository link

---

## Summary

**You need to provide:**
1. ✅ All Azure resources deployed (screenshots)
2. ✅ Working application URLs (with screenshots)
3. ✅ CRUD functionality working (screenshots/videos)
4. ✅ Configuration proof (Key Vault, Managed Identity, etc.)
5. ✅ Database table created (screenshot)
6. ✅ API endpoints working (screenshots)
7. ✅ Documentation of deployment process

**Most Important:**
- **Working application** accessible via URLs
- **All 6 infrastructure components** deployed
- **CRUD operations** functional
- **Security** configured (Key Vault + Managed Identity)

---

## Example Submission Format

```
Project: Azure High Availability CRUD Application

1. Infrastructure Screenshots:
   - [Attach screenshots of all resources in Azure Portal]

2. Application URLs:
   - East US: https://...
   - Central US: https://...
   - Traffic Manager: https://...

3. Application Screenshots:
   - [Attach screenshots of CRUD operations]

4. Configuration Proof:
   - [Attach screenshots of Key Vault, Managed Identity, etc.]

5. Database Evidence:
   - [Attach screenshot of Items table with data]

6. API Testing:
   - [Attach screenshots of API responses]
```

