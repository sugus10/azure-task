# Azure High Availability CRUD Application

This project contains scripts to deploy a highly available infrastructure on Azure using App Services, Traffic Manager, Key Vault, and SQL Database. It also includes a complete CRUD application with a responsive UI that connects to the Azure SQL Database.

## Architecture Overview

The infrastructure consists of:

1. Two App Service Plans and Web Apps deployed in:
   - East US region
   - Central US region

2. Azure Traffic Manager with Performance routing method to direct traffic to the closest web app with lowest latency

3. Azure Key Vault to securely store secrets (SQL connection string)

4. Azure SQL Database in West US region (due to availability constraints in East US)

5. Managed Identity for Web Apps to securely access Key Vault

## Deployment

### Prerequisites

- Azure CLI installed and configured
- Azure subscription
- Bash shell environment
- Node.js and npm installed

### Infrastructure Deployment Steps

1. Make the infrastructure script executable:
   ```bash
   chmod +x azure-infrastructure.sh
   ```

2. Run the infrastructure deployment script:
   ```bash
   ./azure-infrastructure.sh
   ```

3. The script will output important resource names at the end of the deployment.

### Application Deployment Steps

1. Make the application deployment script executable:
   ```bash
   chmod +x deploy.sh
   ```

2. Run the application deployment script:
   ```bash
   ./deploy.sh
   ```

3. The application will be deployed to both web apps and available through the Traffic Manager endpoint.

## Infrastructure Details

### App Service Plans and Web Apps

- Two App Service Plans (S1 tier) in East US and Central US
- Two Web Apps deployed to these App Service Plans
- Managed Identity enabled on both Web Apps

### Azure Key Vault

- Stores the SQL Database connection string securely
- Access policies configured for both Web Apps using their managed identities

### Azure SQL Database

- SQL Server and Database deployed in West US
- Connection string stored as a secret in Key Vault with name "name_surname_1"

### Traffic Manager

- Performance routing method to ensure lowest latency
- Both Web Apps registered as endpoints

### Web App Configuration

- Application setting "ConnectionString" configured to retrieve the connection string from Key Vault

## Security Features

- Managed Identity for secure access to Key Vault
- Secrets stored in Key Vault rather than application settings
- SQL Server firewall configured to allow Azure services

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

## Notes

- Resource names include timestamps to ensure uniqueness
- The scripts include proper error handling and progress reporting
- The application automatically initializes the database table if it doesn't exist
