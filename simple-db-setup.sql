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
