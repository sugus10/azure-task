# Creating the Database Table Manually

Since the Azure CLI command for executing SQL scripts isn't working, you'll need to create the table manually using the Azure Portal Query Editor. Here's how:

## Step 1: Access the Azure Portal
1. Go to [Azure Portal](https://portal.azure.com)
2. Sign in with your Azure account

## Step 2: Navigate to your SQL Database
1. Search for "SQL databases" in the search bar
2. Click on your database: `myDatabase`
3. In the left menu, click on "Query editor"
4. Sign in using these credentials:
   - Username: `sqladmin`
   - Password: `P@ssw0rd1761895912` (or your actual password)

## Step 3: Execute the SQL Script
Copy and paste this SQL script into the query editor, then click "Run":

```sql
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
```

## Step 4: Verify the Table
After running the script, you should see the sample data displayed in the results pane.

## Step 5: Restart the Web App
Run this command to restart the web app:

```bash
az webapp restart --name EastUSWebApp1761895912 --resource-group EastUSResourceGroup
```

## Step 6: Access the Website
After restarting the web app, wait about 30 seconds and then access the website:

```
https://EastUSWebApp1761895912.azurewebsites.net
```

You should now see the website with the sample items displayed.
