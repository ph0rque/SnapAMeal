const { initializeApp } = require('firebase/app');
const { getFirestore, collection, getDocs, deleteDoc, doc, writeBatch } = require('firebase/firestore');

// Firebase configuration for the project
const firebaseConfig = {
  projectId: 'snapameal-cabc7',
  apiKey: process.env.FIREBASE_API_KEY || 'demo-key',
  authDomain: 'snapameal-cabc7.firebaseapp.com',
  storageBucket: 'snapameal-cabc7.appspot.com',
  messagingSenderId: '1027682286218',
  appId: '1:1027682286218:web:demo'
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

async function cleanupCorruptedMeals() {
  console.log('🧹 Starting cleanup of corrupted meal documents...');
  
  try {
    // Get all documents from meal_logs collection
    const mealsRef = collection(db, 'meal_logs');
    const snapshot = await getDocs(mealsRef);
    
    console.log(`📊 Found ${snapshot.size} total meal documents`);
    
    let corruptedCount = 0;
    let deletedCount = 0;
    const corruptedDocs = [];
    
    // First pass: identify corrupted documents
    snapshot.forEach((docSnap) => {
      const data = docSnap.data();
      
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
        console.log(`🗑️  Found corrupted document: ${docSnap.id}`);
        console.log(`   - image_url: ${data.image_url}`);
        console.log(`   - image_path: ${data.image_path}`);
        console.log(`   - user_id: ${data.user_id}`);
        console.log(`   - timestamp: ${data.timestamp}`);
        
        corruptedDocs.push(docSnap.ref);
      }
    });
    
    if (corruptedDocs.length === 0) {
      console.log('🎉 No corrupted documents found - database is clean!');
      return;
    }
    
    console.log(`\n🗑️  Deleting ${corruptedDocs.length} corrupted documents...`);
    
    // Delete documents in batches
    const batchSize = 500;
    for (let i = 0; i < corruptedDocs.length; i += batchSize) {
      const batch = writeBatch(db);
      const batchDocs = corruptedDocs.slice(i, i + batchSize);
      
      batchDocs.forEach((docRef) => {
        batch.delete(docRef);
      });
      
      console.log(`💾 Committing batch ${Math.floor(i / batchSize) + 1} (${batchDocs.length} documents)...`);
      await batch.commit();
      deletedCount += batchDocs.length;
    }
    
    console.log('\n✅ Cleanup completed successfully!');
    console.log(`📊 Summary:`);
    console.log(`   - Total documents checked: ${snapshot.size}`);
    console.log(`   - Corrupted documents found: ${corruptedCount}`);
    console.log(`   - Documents deleted: ${deletedCount}`);
    console.log(`   - Valid documents remaining: ${snapshot.size - deletedCount}`);
    console.log(`🗑️  Successfully removed ${deletedCount} corrupted meal documents`);
    
  } catch (error) {
    console.error('❌ Error during cleanup:', error);
    throw error;
  }
}

// Run the cleanup
cleanupCorruptedMeals()
  .then(() => {
    console.log('🏁 Script completed');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Script failed:', error);
    process.exit(1);
  }); 