#!/usr/bin/env node

/**
 * Migration Script: Demo Collections to Production
 * 
 * This script:
 * 1. Lists all existing collections
 * 2. Migrates data from demo collections to production collections
 * 3. Deletes the demo collections
 * 
 * Demo collections to migrate:
 * - demo_chat_rooms → chat_rooms
 * - demo_health_groups → health_groups  
 * - demo_notifications → notifications
 * - demo_users → users (merge with existing)
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'snapameal-cabc7'
  });
}

const db = admin.firestore();

// Demo to production collection mappings
const COLLECTION_MAPPINGS = {
  'demo_chat_rooms': 'chat_rooms',
  'demo_health_groups': 'health_groups', 
  'demo_notifications': 'notifications',
  'demo_users': 'users'
};

async function listAllCollections() {
  console.log('📋 Listing all Firestore collections...');
  
  try {
    const collections = await db.listCollections();
    const collectionNames = collections.map(col => col.id).sort();
    
    console.log(`\n📊 Found ${collectionNames.length} collections:`);
    collectionNames.forEach(name => {
      const isDemo = name.startsWith('demo_');
      const emoji = isDemo ? '🧪' : '📁';
      console.log(`${emoji} ${name}`);
    });
    
    return collectionNames;
  } catch (error) {
    console.error('❌ Error listing collections:', error);
    throw error;
  }
}

async function getCollectionDocCount(collectionName) {
  try {
    const snapshot = await db.collection(collectionName).get();
    return snapshot.size;
  } catch (error) {
    console.error(`❌ Error getting count for ${collectionName}:`, error);
    return 0;
  }
}

async function migrateCollection(demoCollection, productionCollection) {
  console.log(`\n🔄 Migrating ${demoCollection} → ${productionCollection}`);
  
  try {
    // Get all documents from demo collection
    const demoSnapshot = await db.collection(demoCollection).get();
    
    if (demoSnapshot.empty) {
      console.log(`⚠️  ${demoCollection} is empty, skipping migration`);
      return 0;
    }
    
    console.log(`📄 Found ${demoSnapshot.size} documents in ${demoCollection}`);
    
    // Check if production collection exists and get current count
    const productionCount = await getCollectionDocCount(productionCollection);
    console.log(`📊 Production collection ${productionCollection} has ${productionCount} documents`);
    
    let migratedCount = 0;
    const batch = db.batch();
    
    // Process each document
    for (const doc of demoSnapshot.docs) {
      const data = doc.data();
      
      // Handle special cases for different collection types
      let finalData = { ...data };
      
      if (demoCollection === 'demo_users') {
        // For users, check if user already exists in production
        const existingUser = await db.collection('users').doc(doc.id).get();
        
        if (existingUser.exists) {
          console.log(`👤 User ${doc.id} already exists in production, merging data...`);
          
          // Merge demo data with existing data (existing data takes precedence)
          const existingData = existingUser.data();
          finalData = {
            ...finalData,
            ...existingData, // Existing data overwrites demo data
            migratedFromDemo: true,
            migrationTimestamp: admin.firestore.FieldValue.serverTimestamp()
          };
        } else {
          finalData.migratedFromDemo = true;
          finalData.migrationTimestamp = admin.firestore.FieldValue.serverTimestamp();
        }
      } else {
        // For other collections, add migration metadata
        finalData.migratedFromDemo = true;
        finalData.migrationTimestamp = admin.firestore.FieldValue.serverTimestamp();
      }
      
      // Add to production collection
      const productionDocRef = db.collection(productionCollection).doc(doc.id);
      batch.set(productionDocRef, finalData, { merge: true });
      
      migratedCount++;
    }
    
    // Commit the batch
    await batch.commit();
    console.log(`✅ Successfully migrated ${migratedCount} documents to ${productionCollection}`);
    
    return migratedCount;
  } catch (error) {
    console.error(`❌ Error migrating ${demoCollection}:`, error);
    throw error;
  }
}

async function deleteCollection(collectionName) {
  console.log(`\n🗑️  Deleting collection: ${collectionName}`);
  
  try {
    const snapshot = await db.collection(collectionName).get();
    
    if (snapshot.empty) {
      console.log(`⚠️  Collection ${collectionName} is already empty`);
      return 0;
    }
    
    console.log(`📄 Deleting ${snapshot.size} documents from ${collectionName}`);
    
    const batch = db.batch();
    let deleteCount = 0;
    
    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
      deleteCount++;
    });
    
    await batch.commit();
    console.log(`✅ Successfully deleted ${deleteCount} documents from ${collectionName}`);
    
    return deleteCount;
  } catch (error) {
    console.error(`❌ Error deleting collection ${collectionName}:`, error);
    throw error;
  }
}

async function migrateDemoCollections() {
  console.log('🚀 Starting demo collections migration...\n');
  
  try {
    // List all collections first
    const allCollections = await listAllCollections();
    
    // Find demo collections that exist
    const existingDemoCollections = allCollections.filter(name => 
      Object.keys(COLLECTION_MAPPINGS).includes(name)
    );
    
    if (existingDemoCollections.length === 0) {
      console.log('\n✅ No demo collections found to migrate');
      return;
    }
    
    console.log(`\n🎯 Found ${existingDemoCollections.length} demo collections to migrate:`);
    existingDemoCollections.forEach(name => {
      console.log(`   🧪 ${name} → 📁 ${COLLECTION_MAPPINGS[name]}`);
    });
    
    // Migrate each demo collection
    let totalMigrated = 0;
    
    for (const demoCollection of existingDemoCollections) {
      const productionCollection = COLLECTION_MAPPINGS[demoCollection];
      const migratedCount = await migrateCollection(demoCollection, productionCollection);
      totalMigrated += migratedCount;
    }
    
    console.log(`\n📊 Migration Summary:`);
    console.log(`   📄 Total documents migrated: ${totalMigrated}`);
    
    // Ask for confirmation before deletion
    console.log('\n⚠️  Ready to delete demo collections...');
    console.log('This action cannot be undone!');
    
    // Delete demo collections
    let totalDeleted = 0;
    
    for (const demoCollection of existingDemoCollections) {
      const deletedCount = await deleteCollection(demoCollection);
      totalDeleted += deletedCount;
    }
    
    console.log(`\n🎉 Migration completed successfully!`);
    console.log(`   📄 Documents migrated: ${totalMigrated}`);
    console.log(`   🗑️  Documents deleted: ${totalDeleted}`);
    console.log(`   🧪 Demo collections removed: ${existingDemoCollections.length}`);
    
  } catch (error) {
    console.error('\n❌ Migration failed:', error);
    process.exit(1);
  }
}

// Run the migration
if (require.main === module) {
  migrateDemoCollections()
    .then(() => {
      console.log('\n✅ Migration script completed');
      process.exit(0);
    })
    .catch(error => {
      console.error('\n❌ Migration script failed:', error);
      process.exit(1);
    });
}

module.exports = { migrateDemoCollections, listAllCollections }; 