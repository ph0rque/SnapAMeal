const admin = require('firebase-admin');
const inquirer = require('inquirer');

// -----------------------------------------------------------------------------
// IMPORTANT: SETUP INSTRUCTIONS
// -----------------------------------------------------------------------------
// 1. GENERATE SERVICE ACCOUNT KEY:
//    - Go to your Firebase Project Settings > Service accounts.
//    - Click "Generate new private key" and save the JSON file.
//    - **DO NOT COMMIT THIS FILE TO GIT.** Add it to your .gitignore.
//
// 2. SET ENVIRONMENT VARIABLE:
//    - Open your terminal and run the following command, replacing the path:
//      export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/serviceAccountKey.json"
//
// 3. INSTALL DEPENDENCIES:
//    - Run the following commands in your project's ROOT directory:
//      npm install firebase-admin inquirer
//
// 4. RUN THE SCRIPT:
//    - From your project's ROOT directory, run:
//      node scripts/cleanup_corrupted_meal_logs.js
// -----------------------------------------------------------------------------

// Initialize Firebase Admin SDK
try {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
} catch (error) {
  console.error('❌ Firebase Admin SDK initialization failed.');
  console.error('Please ensure you have set the GOOGLE_APPLICATION_CREDENTIALS environment variable correctly.');
  console.error('Error details:', error.message);
  process.exit(1);
}


const db = admin.firestore();

async function findCorruptedMealLogs() {
  console.log('🔍 Searching for corrupted meal logs in the "meal_logs" collection...');

  const corruptedDocs = new Map();

  // Firestore doesn't support OR queries across different fields,
  // so we perform three separate queries and merge the results.

  // Query 1: Find documents with null imageUrl
  const nullImageUrlSnapshot = await db.collection('meal_logs').where('imageUrl', '==', null).get();
  nullImageUrlSnapshot.forEach(doc => {
    corruptedDocs.set(doc.id, doc.data());
  });
  console.log(`- Found ${nullImageUrlSnapshot.size} documents with null 'imageUrl'.`);

  // Query 2: Find documents with null imagePath
  const nullImagePathSnapshot = await db.collection('meal_logs').where('imagePath', '==', null).get();
  nullImagePathSnapshot.forEach(doc => {
    corruptedDocs.set(doc.id, doc.data());
  });
  console.log(`- Found ${nullImagePathSnapshot.size} documents with null 'imagePath'.`);

  // Query 3: Find documents with null userId
  const nullUserIdSnapshot = await db.collection('meal_logs').where('userId', '==', null).get();
  nullUserIdSnapshot.forEach(doc => {
    corruptedDocs.set(doc.id, doc.data());
  });
  console.log(`- Found ${nullUserIdSnapshot.size} documents with null 'userId'.`);

  console.log(`\n✅ Total unique corrupted documents found: ${corruptedDocs.size}`);
  
  return Array.from(corruptedDocs.keys());
}

async function deleteDocsInBatch(docIds) {
  if (docIds.length === 0) {
    console.log('👍 No corrupted documents to delete.');
    return;
  }

  const batch = db.batch();
  docIds.forEach(id => {
    const docRef = db.collection('meal_logs').doc(id);
    batch.delete(docRef);
  });

  console.log(`\n🔥 Deleting ${docIds.length} documents...`);
  await batch.commit();
  console.log('✅ Successfully deleted all corrupted meal logs.');
}

async function main() {
  try {
    const corruptedIds = await findCorruptedMealLogs();

    if (corruptedIds.length === 0) {
      return;
    }

    const { confirm } = await inquirer.prompt([
      {
        type: 'confirm',
        name: 'confirm',
        message: `Are you sure you want to permanently delete these ${corruptedIds.length} documents? This action cannot be undone.`,
        default: false,
      },
    ]);

    if (confirm) {
      await deleteDocsInBatch(corruptedIds);
    } else {
      console.log('\n🚫 Deletion cancelled by user. No documents were deleted.');
    }
  } catch (error) {
    console.error('\n❌ An error occurred during the cleanup process:');
    console.error(error);
    process.exit(1);
  }
}

main(); 