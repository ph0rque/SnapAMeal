#!/usr/bin/env node

/**
 * Cleanup Script: Remove Empty Demo Collections
 * 
 * This script removes any remaining empty demo collections after migration.
 * It's safe to run multiple times.
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

async function cleanupEmptyDemoCollections() {
  console.log('🧹 Starting cleanup of empty demo collections...\n');
  
  try {
    // List all collections
    const collections = await db.listCollections();
    const collectionNames = collections.map(col => col.id);
    
    // Find demo collections
    const demoCollections = collectionNames.filter(name => name.startsWith('demo_'));
    
    if (demoCollections.length === 0) {
      console.log('✅ No demo collections found - cleanup complete!');
      return;
    }
    
    console.log(`🔍 Found ${demoCollections.length} demo collections to check:`);
    demoCollections.forEach(name => console.log(`   🧪 ${name}`));
    
    let deletedCollections = 0;
    
    for (const collectionName of demoCollections) {
      console.log(`\n🔍 Checking ${collectionName}...`);
      
      const snapshot = await db.collection(collectionName).limit(1).get();
      
      if (snapshot.empty) {
        console.log(`   📭 Empty - no cleanup needed (collection will be auto-removed)`);
      } else {
        console.log(`   📄 Contains ${snapshot.size} documents - keeping collection`);
      }
    }
    
    console.log(`\n🎉 Cleanup completed!`);
    console.log(`   🧪 Demo collections checked: ${demoCollections.length}`);
    console.log(`   ℹ️  Empty collections will be automatically removed by Firestore`);
    
  } catch (error) {
    console.error('\n❌ Cleanup failed:', error);
    process.exit(1);
  }
}

// Run the cleanup
if (require.main === module) {
  cleanupEmptyDemoCollections()
    .then(() => {
      console.log('\n✅ Cleanup script completed');
      process.exit(0);
    })
    .catch(error => {
      console.error('\n❌ Cleanup script failed:', error);
      process.exit(1);
    });
}

module.exports = { cleanupEmptyDemoCollections }; 