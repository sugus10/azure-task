const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const sql = require('mssql');
const path = require('path');

// Initialize Express app
const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// Database configuration
// In production, this will be replaced by KeyVault reference
const dbConfig = {
  server: process.env.DB_SERVER || 'localhost',
  database: process.env.DB_DATABASE || 'myDatabase',
  user: process.env.DB_USER || 'sa',
  password: process.env.DB_PASSWORD || 'YourPassword',
  port: parseInt(process.env.DB_PORT || '1433'),
  options: {
    encrypt: true,
    enableArithAbort: true,
    trustServerCertificate: true // For local dev only
  }
};

// Create SQL connection pool
const pool = new sql.ConnectionPool(dbConfig);
const poolConnect = pool.connect();

// Handle database connection errors
poolConnect.catch(err => {
  console.error('Error connecting to database:', err);
});

// API Routes
// Get all items
app.get('/api/items', async (req, res) => {
  try {
    await poolConnect;
    const request = pool.request();
    const result = await request.query('SELECT * FROM Items');
    res.json(result.recordset);
  } catch (err) {
    console.error('Error fetching items:', err);
    res.status(500).json({ error: 'Failed to fetch items' });
  }
});

// Get single item
app.get('/api/items/:id', async (req, res) => {
  try {
    await poolConnect;
    const request = pool.request();
    request.input('id', sql.Int, req.params.id);
    const result = await request.query('SELECT * FROM Items WHERE id = @id');
    
    if (result.recordset.length === 0) {
      return res.status(404).json({ error: 'Item not found' });
    }
    
    res.json(result.recordset[0]);
  } catch (err) {
    console.error('Error fetching item:', err);
    res.status(500).json({ error: 'Failed to fetch item' });
  }
});

// Create new item
app.post('/api/items', async (req, res) => {
  try {
    const { name, description } = req.body;
    
    if (!name) {
      return res.status(400).json({ error: 'Name is required' });
    }
    
    await poolConnect;
    const request = pool.request();
    request.input('name', sql.NVarChar, name);
    request.input('description', sql.NVarChar, description || '');
    
    const result = await request.query(`
      INSERT INTO Items (name, description, createdAt)
      OUTPUT INSERTED.*
      VALUES (@name, @description, GETDATE())
    `);
    
    res.status(201).json(result.recordset[0]);
  } catch (err) {
    console.error('Error creating item:', err);
    res.status(500).json({ error: 'Failed to create item' });
  }
});

// Update item
app.put('/api/items/:id', async (req, res) => {
  try {
    const { name, description } = req.body;
    
    if (!name) {
      return res.status(400).json({ error: 'Name is required' });
    }
    
    await poolConnect;
    const request = pool.request();
    request.input('id', sql.Int, req.params.id);
    request.input('name', sql.NVarChar, name);
    request.input('description', sql.NVarChar, description || '');
    
    const result = await request.query(`
      UPDATE Items
      SET name = @name, description = @description, updatedAt = GETDATE()
      OUTPUT INSERTED.*
      WHERE id = @id
    `);
    
    if (result.recordset.length === 0) {
      return res.status(404).json({ error: 'Item not found' });
    }
    
    res.json(result.recordset[0]);
  } catch (err) {
    console.error('Error updating item:', err);
    res.status(500).json({ error: 'Failed to update item' });
  }
});

// Delete item
app.delete('/api/items/:id', async (req, res) => {
  try {
    await poolConnect;
    const request = pool.request();
    request.input('id', sql.Int, req.params.id);
    
    const result = await request.query(`
      DELETE FROM Items
      OUTPUT DELETED.*
      WHERE id = @id
    `);
    
    if (result.recordset.length === 0) {
      return res.status(404).json({ error: 'Item not found' });
    }
    
    res.json({ message: 'Item deleted successfully' });
  } catch (err) {
    console.error('Error deleting item:', err);
    res.status(500).json({ error: 'Failed to delete item' });
  }
});

// Serve the main HTML page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Initialize database
async function initializeDatabase() {
  try {
    await poolConnect;
    const request = pool.request();
    
    // Check if Items table exists, if not create it
    const result = await request.query(`
      IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Items' and xtype='U')
      CREATE TABLE Items (
        id INT PRIMARY KEY IDENTITY(1,1),
        name NVARCHAR(100) NOT NULL,
        description NVARCHAR(500),
        createdAt DATETIME NOT NULL,
        updatedAt DATETIME
      )
    `);
    
    // Insert some sample data if table is empty
    const countResult = await request.query('SELECT COUNT(*) as count FROM Items');
    if (countResult.recordset[0].count === 0) {
      console.log('Adding sample data...');
      await request.query(`
        INSERT INTO Items (name, description, createdAt)
        VALUES 
          ('Sample Item 1', 'This is a sample item for demonstration', GETDATE()),
          ('Sample Item 2', 'Another example item to show CRUD functionality', GETDATE()),
          ('Sample Item 3', 'A third item to populate the initial view', GETDATE())
      `);
    }
    
    console.log('Database initialized successfully');
  } catch (err) {
    console.error('Error initializing database:', err);
  }
}

// Start the server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
  initializeDatabase();
});

// Handle shutdown gracefully
process.on('SIGTERM', () => {
  pool.close();
  process.exit(0);
});
