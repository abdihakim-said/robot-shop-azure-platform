// MongoDB User Initialization Script
// This script creates users with passwords from environment variables
// It runs automatically when MongoDB starts for the first time

// Get passwords from environment variables (set by Azure Key Vault)
const cataloguePassword = process.env.MONGO_CATALOGUE_PASSWORD;
const usersPassword = process.env.MONGO_USERS_PASSWORD;
const rootPassword = process.env.MONGO_INITDB_ROOT_PASSWORD;

// Validate required environment variables
if (!cataloguePassword || !usersPassword || !rootPassword) {
    print('ERROR: Required password environment variables not set');
    print('MONGO_CATALOGUE_PASSWORD:', cataloguePassword ? 'SET' : 'MISSING');
    print('MONGO_USERS_PASSWORD:', usersPassword ? 'SET' : 'MISSING');
    print('MONGO_INITDB_ROOT_PASSWORD:', rootPassword ? 'SET' : 'MISSING');
    print('Cannot create users without Azure Key Vault passwords');
    quit(1);
}

print('Creating MongoDB users...');

// Switch to admin database to create root user
db = db.getSiblingDB('admin');

// Create root user if it doesn't exist
try {
    db.createUser({
        user: 'root',
        pwd: rootPassword,
        roles: [
            { role: 'root', db: 'admin' }
        ]
    });
    print('Root user created successfully');
} catch (e) {
    if (e.code === 51003) {
        print('Root user already exists');
    } else {
        print('Error creating root user: ' + e);
    }
}

// Switch to catalogue database
db = db.getSiblingDB('catalogue');

// Create catalogue user with read/write access to catalogue database
try {
    db.createUser({
        user: 'catalogue',
        pwd: cataloguePassword,
        roles: [
            { role: 'readWrite', db: 'catalogue' }
        ]
    });
    print('Catalogue user created successfully');
} catch (e) {
    if (e.code === 51003) {
        print('Catalogue user already exists');
    } else {
        print('Error creating catalogue user: ' + e);
    }
}

// Switch to users database
db = db.getSiblingDB('users');

// Create users user with read/write access to users database
try {
    db.createUser({
        user: 'users',
        pwd: usersPassword,
        roles: [
            { role: 'readWrite', db: 'users' }
        ]
    });
    print('Users user created successfully');
} catch (e) {
    if (e.code === 51003) {
        print('Users user already exists');
    } else {
        print('Error creating users user: ' + e);
    }
}

print('User initialization completed');
