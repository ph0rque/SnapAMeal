// Simple script to identify corrupted meal documents
// Run with: node scripts/find_corrupted_meals.js

console.log('📋 Corrupted Meal Document Finder');
console.log('=====================================');
console.log('');
console.log('This script helps identify which meal documents need manual cleanup.');
console.log('Look for documents in Firebase Console with these characteristics:');
console.log('');
console.log('🔍 **What to look for in Firestore Console:**');
console.log('   - Documents where image_url = null or empty string');
console.log('   - Documents where image_path = null or empty string');  
console.log('   - Documents where user_id = null or empty string');
console.log('');
console.log('📱 **How to clean up manually:**');
console.log('   1. Go to https://console.firebase.google.com/project/snapameal-cabc7/firestore');
console.log('   2. Click on the "meal_logs" collection');
console.log('   3. Look through the documents for ones with null/empty fields');
console.log('   4. Click on each corrupted document and delete it');
console.log('');
console.log('🎯 **Example of corrupted document data:**');
console.log('   {');
console.log('     "id": "some_document_id",');
console.log('     "image_url": null,           // ← This indicates corruption');
console.log('     "image_path": null,          // ← This indicates corruption');
console.log('     "user_id": null,             // ← This indicates corruption');
console.log('     "timestamp": "some_timestamp"');
console.log('   }');
console.log('');
console.log('✅ **What good documents look like:**');
console.log('   {');
console.log('     "id": "some_document_id",');
console.log('     "image_url": "https://firebasestorage...",  // ← Has valid URL');
console.log('     "image_path": "/path/to/image.jpg",         // ← Has valid path');
console.log('     "user_id": "user123",                      // ← Has valid user ID');
console.log('     "timestamp": "some_timestamp"');
console.log('   }');
console.log('');
console.log('🔧 **After cleanup, the My Meals UI should only show valid meals with images!**');

// You could add actual Firebase querying here if authentication issues are resolved 