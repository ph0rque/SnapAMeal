#!/usr/bin/env node

/**
 * Migration Script: Demo Meal Logs to Production
 * 
 * This script migrates demo_meal_logs to production meal_logs collection
 * so demo users can see their meal history in the My Meals page.
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

async function migrateDemoMealLogs() {
  console.log('🚀 Starting demo_meal_logs migration to meal_logs...\n');
  
  try {
    // Check if demo_meal_logs collection exists
    const demoSnapshot = await db.collection('demo_meal_logs').limit(1).get();
    
    if (demoSnapshot.empty) {
      console.log('✅ No demo_meal_logs data found - migration not needed');
      return;
    }
    
    // Get all documents from demo_meal_logs
    const allDemoMeals = await db.collection('demo_meal_logs').get();
    console.log(`📄 Found ${allDemoMeals.size} meal logs in demo_meal_logs`);
    
    // Check existing meal_logs count
    const productionSnapshot = await db.collection('meal_logs').get();
    console.log(`📊 Production meal_logs currently has ${productionSnapshot.size} documents`);
    
    let migratedCount = 0;
    const batch = db.batch();
    
    // Process each demo meal log
    for (const doc of allDemoMeals.docs) {
      const data = doc.data();
      
      // Add migration metadata
      const finalData = {
        ...data,
        migratedFromDemo: true,
        migrationTimestamp: admin.firestore.FieldValue.serverTimestamp(),
        originalDemoId: doc.id
      };
      
      // Create new document in production meal_logs
      const productionDocRef = db.collection('meal_logs').doc(doc.id);
      batch.set(productionDocRef, finalData, { merge: true });
      
      migratedCount++;
    }
    
    // Commit the batch
    await batch.commit();
    console.log(`✅ Successfully migrated ${migratedCount} meal logs to production`);
    
    // Delete demo_meal_logs collection
    console.log('\n🗑️  Deleting demo_meal_logs collection...');
    const deleteBatch = db.batch();
    
    allDemoMeals.docs.forEach(doc => {
      deleteBatch.delete(doc.ref);
    });
    
    await deleteBatch.commit();
    console.log(`✅ Successfully deleted ${allDemoMeals.size} documents from demo_meal_logs`);
    
    console.log('\n🎉 Demo meal logs migration completed successfully!');
    console.log(`   📄 Documents migrated: ${migratedCount}`);
    console.log(`   🗑️  Documents deleted: ${allDemoMeals.size}`);
    console.log(`   📊 Total meal_logs now: ${productionSnapshot.size + migratedCount}`);
    
  } catch (error) {
    console.error('\n❌ Migration failed:', error);
    process.exit(1);
  }
}

// Run the migration
if (require.main === module) {
  migrateDemoMealLogs()
    .then(() => {
      console.log('\n✅ Migration script completed');
      process.exit(0);
    })
    .catch(error => {
      console.error('\n❌ Migration script failed:', error);
      process.exit(1);
    });
}

module.exports = { migrateDemoMealLogs }; 