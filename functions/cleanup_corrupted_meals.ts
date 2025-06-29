import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK with project ID
if (!admin.apps.length) {
  admin.initializeApp({
    projectId: 'snapameal-cabc7'
  });
}

const db = admin.firestore();

export async function cleanupCorruptedMeals(): Promise<void> {
  console.log('🧹 Starting cleanup of corrupted meal documents...');
  
  try {
    // Get all documents from meal_logs collection
    const mealsRef = db.collection('meal_logs');
    const snapshot = await mealsRef.get();
    
    console.log(`📊 Found ${snapshot.size} total meal documents`);
    
    let corruptedCount = 0;
    let deletedCount = 0;
    let batch = db.batch();
    const batchSize = 500; // Firestore batch limit
    let currentBatch = 0;
    
    for (const doc of snapshot.docs) {
      const data = doc.data();
      
      // Check if document is corrupted (has null values for critical fields)
      const isCorrupted = (
        data.image_url === null || 
        data.image_url === undefined || 
        data.image_url === '' ||
        data.image_path === null || 
        data.image_path === undefined || 
        data.image_path === '' ||
        data.user_id === null || 
        data.user_id === undefined || 
        data.user_id === ''
      );
      
      if (isCorrupted) {
        corruptedCount++;
        console.log(`🗑️  Marking for deletion: ${doc.id}`);
        console.log(`   - image_url: ${data.image_url}`);
        console.log(`   - image_path: ${data.image_path}`);
        console.log(`   - user_id: ${data.user_id}`);
        console.log(`   - timestamp: ${data.timestamp}`);
        
        batch.delete(doc.ref);
        currentBatch++;
        
        // Commit batch if we hit the limit
        if (currentBatch >= batchSize) {
          console.log(`💾 Committing batch of ${currentBatch} deletions...`);
          await batch.commit();
          deletedCount += currentBatch;
          batch = db.batch(); // Create new batch
          currentBatch = 0;
        }
      }
    }
    
    // Commit any remaining deletions
    if (currentBatch > 0) {
      console.log(`💾 Committing final batch of ${currentBatch} deletions...`);
      await batch.commit();
      deletedCount += currentBatch;
    }
    
    console.log('\n✅ Cleanup completed successfully!');
    console.log(`📊 Summary:`);
    console.log(`   - Total documents checked: ${snapshot.size}`);
    console.log(`   - Corrupted documents found: ${corruptedCount}`);
    console.log(`   - Documents deleted: ${deletedCount}`);
    console.log(`   - Valid documents remaining: ${snapshot.size - deletedCount}`);
    
    if (deletedCount === 0) {
      console.log('🎉 No corrupted documents found - database is clean!');
    } else {
      console.log(`🗑️  Successfully removed ${deletedCount} corrupted meal documents`);
    }
    
  } catch (error) {
    console.error('❌ Error during cleanup:', error);
    throw error;
  }
}

// Main execution function
async function main(): Promise<void> {
  try {
    await cleanupCorruptedMeals();
    console.log('🏁 Script completed');
    process.exit(0);
  } catch (error) {
    console.error('💥 Script failed:', error);
    process.exit(1);
  }
}

// Run the cleanup if this script is executed directly
if (require.main === module) {
  main();
} 