# Azure High Availability CRUD Application

This project deploys a highly available CRUD application on Azure using App Services, Traffic Manager, Key Vault, and SQL Database.

## Task Requirements

1. Create Azure App Service Plans with Azure App Services in East US and Central US
2. Build highly available load balancer infrastructure using Traffic Manager with Performance routing
3. Create Azure Key Vault service
4. Create Azure SQL Database in West US
5. Store SQL connection string in Azure Key Vault
6. Configure web apps to access Key Vault using managed identities

## Deployment Instructions

### Prerequisites

- Azure CLI installed and configured
- Azure subscription
- Bash shell environment
- Node.js and npm installed

### Option 1: Automated Deployment

1. Make the setup script executable:
   ```bash
   chmod +x azure-setup.sh
   ```

2. Run the setup script:
   ```bash
   ./azure-setup.sh
   ```

3. After the script completes, follow the instructions to set up the database table using the Azure Portal Query Editor.

### Option 2: Manual Deployment

Follow the step-by-step instructions in the `azure-manual-setup.md` file to manually deploy the infrastructure through the Azure Portal.

## Application Details

### Features

- Complete CRUD operations (Create, Read, Update, Delete)
- Responsive UI built with Bootstrap 5
- RESTful API endpoints
- SQL Database integration
- Secure connection string storage in Key Vault

### Technology Stack

- **Backend**: Node.js with Express
- **Database**: Azure SQL Database
- **Frontend**: HTML, CSS, JavaScript with Bootstrap 5
- **Security**: Azure Key Vault, Managed Identity

### API Endpoints

- `GET /api/items` - Get all items
- `GET /api/items/:id` - Get a specific item
- `POST /api/items` - Create a new item
- `PUT /api/items/:id` - Update an existing item
- `DELETE /api/items/:id` - Delete an item

## Troubleshooting

If you encounter issues:

1. Check Web App logs:
   - Go to each Web App in the Azure Portal
   - Navigate to "Log stream" in the left menu

2. Verify Key Vault access:
   - Check that managed identities are enabled
   - Verify access policies are correctly set up

3. Check database connectivity:
   - Verify firewall rules allow Azure services
   - Check that the connection string is correct