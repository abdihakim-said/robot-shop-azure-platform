// Post-deployment user creation script
// This script can be run against an existing MongoDB instance
// Usage: mongosh admin -u admin -p <password> --file create-users.js

// Get passwords from environment or use defaults for testing
const cataloguePassword = process.env.MONGO_CATALOGUE_PASSWORD || 'G9l1snwRf9YWHM2ySH7qQEyEcm+FZkm7w1Xy0le9zYc=';
const usersPassword = process.env.MONGO_USERS_PASSWORD || 'tH+HLwohiJlLly4KWU9/yDEQoiP3Lp0qaxktwdQ3ahU=';

print('Creating application users...');

// Create catalogue user
try {
    use('catalogue');
    db.createUser({
        user: 'catalogue',
        pwd: cataloguePassword,
        roles: [{ role: 'readWrite', db: 'catalogue' }]
    });
    print('✅ Catalogue user created successfully');
} catch (e) {
    if (e.code === 51003) {
        print('ℹ️  Catalogue user already exists');
    } else {
        print('❌ Error creating catalogue user: ' + e);
    }
}

// Create users user
try {
    use('users');
    db.createUser({
        user: 'users',
        pwd: usersPassword,
        roles: [{ role: 'readWrite', db: 'users' }]
    });
    print('✅ Users user created successfully');
} catch (e) {
    if (e.code === 51003) {
        print('ℹ️  Users user already exists');
    } else {
        print('❌ Error creating users user: ' + e);
    }
}

print('🎉 User creation completed');
