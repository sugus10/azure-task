#!/bin/bash

# Variables
SQL_SERVER_NAME="sqlserver1761895912"
SQL_DB_NAME="myDatabase"
SQL_ADMIN_USER="sqladmin"
SQL_ADMIN_PASSWORD="P@ssw0rd1761895912"  # Replace with your actual password

echo "Testing SQL Server connectivity..."

# Install sqlcmd if not already installed
echo "Checking if sqlcmd is installed..."
if ! command -v sqlcmd &> /dev/null; then
    echo "sqlcmd not found. Please install the SQL Server command-line tools."
    echo "For Windows: https://docs.microsoft.com/en-us/sql/tools/sqlcmd-utility"
    echo "For Linux/Mac: https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools"
    exit 1
fi

# Test connection to SQL Server
echo "Attempting to connect to SQL Server..."
sqlcmd -S "$SQL_SERVER_NAME.database.windows.net" -d "$SQL_DB_NAME" -U "$SQL_ADMIN_USER" -P "$SQL_ADMIN_PASSWORD" -Q "SELECT @@VERSION"

# Check if Items table exists
echo "Checking if Items table exists..."
sqlcmd -S "$SQL_SERVER_NAME.database.windows.net" -d "$SQL_DB_NAME" -U "$SQL_ADMIN_USER" -P "$SQL_ADMIN_PASSWORD" -Q "IF OBJECT_ID('Items', 'U') IS NOT NULL SELECT 'Table exists' AS Status ELSE SELECT 'Table does not exist' AS Status"

# Create Items table if it doesn't exist
echo "Creating Items table if it doesn't exist..."
sqlcmd -S "$SQL_SERVER_NAME.database.windows.net" -d "$SQL_DB_NAME" -U "$SQL_ADMIN_USER" -P "$SQL_ADMIN_PASSWORD" -Q "
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Items' and xtype='U')
CREATE TABLE Items (
  id INT PRIMARY KEY IDENTITY(1,1),
  name NVARCHAR(100) NOT NULL,
  description NVARCHAR(500),
  createdAt DATETIME NOT NULL,
  updatedAt DATETIME
)"

# Insert sample data
echo "Inserting sample data..."
sqlcmd -S "$SQL_SERVER_NAME.database.windows.net" -d "$SQL_DB_NAME" -U "$SQL_ADMIN_USER" -P "$SQL_ADMIN_PASSWORD" -Q "
IF (SELECT COUNT(*) FROM Items) = 0
BEGIN
  INSERT INTO Items (name, description, createdAt)
  VALUES 
    ('Sample Item 1', 'This is a sample item for demonstration', GETDATE()),
    ('Sample Item 2', 'Another example item to show CRUD functionality', GETDATE()),
    ('Sample Item 3', 'A third item to populate the initial view', GETDATE())
END"

# Verify data
echo "Verifying data in Items table..."
sqlcmd -S "$SQL_SERVER_NAME.database.windows.net" -d "$SQL_DB_NAME" -U "$SQL_ADMIN_USER" -P "$SQL_ADMIN_PASSWORD" -Q "SELECT * FROM Items"

echo "SQL connection test completed!"
