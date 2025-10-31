// Add error handlers FIRST, before anything else
process.on('unhandledRejection', (reason, promise) => {
  console.error('========================================');
  console.error('Unhandled Rejection at:', promise);
  console.error('Reason:', reason);
  console.error('Stack:', reason && reason.stack ? reason.stack : 'No stack trace');
  console.error('========================================');
});

process.on('uncaughtException', (err) => {
  console.error('========================================');
  console.error('Uncaught Exception:', err);
  console.error('Stack:', err.stack);
  console.error('========================================');
  // Don't exit, let the app continue
});

// Log immediately to ensure we can see this in Azure logs
console.log('========================================');
console.log('Application starting...');
console.log('Time:', new Date().toISOString());
console.log('Node version:', process.version);
console.log('========================================');

const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const sql = require('mssql');
const path = require('path');

console.log('Express and other modules loaded successfully');

// Initialize Express app
const app = express();
const port = process.env.PORT || 3000;

console.log('Express app initialized, port:', port);

console.log('Setting up middleware...');

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

console.log('Middleware configured, static files from:', path.join(__dirname, 'public'));

// Database configuration
// Parse connection string from Key Vault or use individual env vars
function parseConnectionString(connStr) {
  const config = {
    options: {
      encrypt: true,
      enableArithAbort: true,
      trustServerCertificate: false
    }
  };
  
  const parts = connStr.split(';');
  parts.forEach(part => {
    const [key, value] = part.split('=').map(s => s.trim());
    if (!key || !value) return;
    
    switch (key.toLowerCase()) {
      case 'server':
        const serverMatch = value.match(/tcp:(.+),(\d+)/);
        if (serverMatch) {
          config.server = serverMatch[1];
          config.port = parseInt(serverMatch[2]);
        }
        break;
      case 'initial catalog':
        config.database = value;
        break;
      case 'user id':
        config.user = value;
        break;
      case 'password':
        config.password = value;
        break;
    }
  });
  
  return config;
}

let pool;
let poolConnect;

console.log('Starting database configuration...');

if (process.env.ConnectionString) {
  console.log('Using connection string from Key Vault');
  const connStr = process.env.ConnectionString;
  console.log('Connection string present:', connStr ? 'Yes' : 'No');
  console.log('Connection string starts with:', connStr ? connStr.substring(0, 50) : 'N/A');
  
  // Check if Key Vault reference wasn't resolved
  if (connStr && connStr.startsWith('@Microsoft.KeyVault')) {
    console.error('ERROR: Key Vault reference not resolved! The connection string still contains the reference format.');
    console.error('This usually means the managed identity does not have proper permissions to access Key Vault.');
    poolConnect = Promise.reject(new Error('Key Vault reference not resolved - check managed identity permissions'));
  } else if (connStr) {
    try {
      const dbConfig = parseConnectionString(connStr);
      console.log('Parsed database config:', { server: dbConfig.server, database: dbConfig.database, user: dbConfig.user });
      pool = new sql.ConnectionPool(dbConfig);
      poolConnect = pool.connect();
      poolConnect.then(() => {
        console.log('Database connection pool established successfully');
      }).catch(err => {
        console.error('Failed to establish database connection pool:', err);
      });
    } catch (err) {
      console.error('Error parsing connection string:', err);
      poolConnect = Promise.reject(err);
    }
  } else {
    poolConnect = Promise.reject(new Error('Connection string is empty'));
  }
} else {
  console.log('Using individual environment variables');
  try {
    const dbConfig = {
      server: process.env.DB_SERVER || 'localhost',
      database: process.env.DB_DATABASE || 'myDatabase',
      user: process.env.DB_USER || 'sa',
      password: process.env.DB_PASSWORD || 'YourPassword',
      port: parseInt(process.env.DB_PORT || '1433'),
      options: {
        encrypt: true,
        enableArithAbort: true,
        trustServerCertificate: false
      }
    };
    pool = new sql.ConnectionPool(dbConfig);
    poolConnect = pool.connect();
    console.log('Database connection pool created with individual env vars');
  } catch (err) {
    console.error('Error creating database connection pool:', err);
    poolConnect = Promise.reject(err);
  }
}

console.log('Database configuration completed');

// Handle database connection errors
poolConnect.catch(err => {
  console.error('Error connecting to database:', err);
});

console.log('Setting up routes...');

// Simple test route
app.get('/test', (req, res) => {
  console.log('GET /test called');
  res.json({ message: 'Server is running!', timestamp: new Date().toISOString() });
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    connectionString: process.env.ConnectionString ? 'Present' : 'Missing',
    nodeVersion: process.version
  });
});

// API Routes
// Get all items
app.get('/api/items', async (req, res) => {
  console.log('GET /api/items called');
  try {
    if (!pool) {
      return res.status(500).json({ error: 'Database connection pool not initialized' });
    }
    console.log('Waiting for database connection...');
    await poolConnect;
    console.log('Database connected, executing query...');
    const request = pool.request();
    const result = await request.query('SELECT * FROM Items');
    console.log('Query successful, returning', result.recordset.length, 'items');
    res.json(result.recordset);
  } catch (err) {
    console.error('Error fetching items:', err);
    console.error('Error details:', JSON.stringify(err, Object.getOwnPropertyNames(err)));
    res.status(500).json({ 
      error: 'Failed to fetch items', 
      message: err.message,
      code: err.code 
    });
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
const server = app.listen(port, () => {
  console.log(`Server running on port ${port}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`ConnectionString env var exists: ${process.env.ConnectionString ? 'Yes' : 'No'}`);
  // Initialize database in background, don't block server startup
  initializeDatabase().catch(err => {
    console.error('Database initialization failed, but server is still running:', err);
  });
});

// Add error handler for server
server.on('error', (err) => {
  console.error('Server error:', err);
  if (err.code === 'EADDRINUSE') {
    console.error(`Port ${port} is already in use`);
  }
});

// Handle shutdown gracefully
process.on('SIGTERM', () => {
  pool.close();
  process.exit(0);
});
