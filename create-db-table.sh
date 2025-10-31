#!/bin/bash

# Variables
RESOURCE_GROUP_WEST="WestUSResourceGroup"
SQL_SERVER_NAME="sqlserver1761895912"
SQL_DB_NAME="myDatabase"
SQL_ADMIN_USER="sqladmin"
SQL_ADMIN_PASSWORD="P@ssw0rd1761895912"  # Replace with your actual password

echo "Creating Items table in the database..."

# Create a temporary SQL script file
cat > create_table.sql << EOF
-- Check if Items table exists, if not create it
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Items' and xtype='U')
BEGIN
    CREATE TABLE Items (
        id INT PRIMARY KEY IDENTITY(1,1),
        name NVARCHAR(100) NOT NULL,
        description NVARCHAR(500),
        createdAt DATETIME NOT NULL,
        updatedAt DATETIME
    );
    
    -- Insert sample data
    INSERT INTO Items (name, description, createdAt)
    VALUES 
        ('Sample Item 1', 'This is a sample item for demonstration', GETDATE()),
        ('Sample Item 2', 'Another example item to show CRUD functionality', GETDATE()),
        ('Sample Item 3', 'A third item to populate the initial view', GETDATE());
        
    PRINT 'Table created and sample data inserted.';
END
ELSE
BEGIN
    -- Check if table is empty
    IF (SELECT COUNT(*) FROM Items) = 0
    BEGIN
        -- Insert sample data
        INSERT INTO Items (name, description, createdAt)
        VALUES 
            ('Sample Item 1', 'This is a sample item for demonstration', GETDATE()),
            ('Sample Item 2', 'Another example item to show CRUD functionality', GETDATE()),
            ('Sample Item 3', 'A third item to populate the initial view', GETDATE());
            
        PRINT 'Sample data inserted into existing table.';
    END
    ELSE
    BEGIN
        PRINT 'Table exists and already has data.';
    END
END

-- Verify data
SELECT * FROM Items;
EOF

# Execute the SQL script using Azure CLI
echo "Executing SQL script to create table and insert data..."
az sql db execute --server $SQL_SERVER_NAME --name $SQL_DB_NAME --resource-group $RESOURCE_GROUP_WEST \
  --user-name $SQL_ADMIN_USER --password $SQL_ADMIN_PASSWORD --file create_table.sql

# Clean up the temporary file
rm create_table.sql

echo "Database setup completed!"
echo "Now try accessing the website again."
