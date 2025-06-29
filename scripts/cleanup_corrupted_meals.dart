import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  print('🧹 Starting cleanup of corrupted meal documents...');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAl_dummy_key', // This won't be used for server-side operations
        authDomain: 'snapameal-cabc7.firebaseapp.com',
        projectId: 'snapameal-cabc7',
        storageBucket: 'snapameal-cabc7.appspot.com',
        messagingSenderId: '1027682286218',
        appId: '1:1027682286218:web:demo',
      ),
    );
    
    await cleanupCorruptedMeals();
    
  } catch (error) {
    print('💥 Script failed: $error');
    exit(1);
  }
}

Future<void> cleanupCorruptedMeals() async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Get all documents from meal_logs collection
    print('📊 Fetching all meal documents...');
    final QuerySnapshot snapshot = await firestore.collection('meal_logs').get();
    
    print('📊 Found ${snapshot.docs.length} total meal documents');
    
    int corruptedCount = 0;
    int deletedCount = 0;
    final List<DocumentReference> corruptedDocs = [];
    
    // First pass: identify corrupted documents
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Check if document is corrupted (has null values for critical fields)
      final bool isCorrupted = (
        data['image_url'] == null || 
        data['image_url'] == '' ||
        data['image_path'] == null || 
        data['image_path'] == '' ||
        data['user_id'] == null || 
        data['user_id'] == ''
      );
      
      if (isCorrupted) {
        corruptedCount++;
        print('🗑️  Found corrupted document: ${doc.id}');
        print('   - image_url: ${data['image_url']}');
        print('   - image_path: ${data['image_path']}');
        print('   - user_id: ${data['user_id']}');
        print('   - timestamp: ${data['timestamp']}');
        
        corruptedDocs.add(doc.reference);
      }
    }
    
    if (corruptedDocs.isEmpty) {
      print('🎉 No corrupted documents found - database is clean!');
      return;
    }
    
    print('\n🗑️  Deleting ${corruptedDocs.length} corrupted documents...');
    
    // Delete documents in batches
    const int batchSize = 500;
    for (int i = 0; i < corruptedDocs.length; i += batchSize) {
      final WriteBatch batch = firestore.batch();
      final List<DocumentReference> batchDocs = corruptedDocs.skip(i).take(batchSize).toList();
      
      for (final docRef in batchDocs) {
        batch.delete(docRef);
      }
      
      print('💾 Committing batch ${(i / batchSize).floor() + 1} (${batchDocs.length} documents)...');
      await batch.commit();
      deletedCount += batchDocs.length;
    }
    
    print('\n✅ Cleanup completed successfully!');
    print('📊 Summary:');
    print('   - Total documents checked: ${snapshot.docs.length}');
    print('   - Corrupted documents found: $corruptedCount');
    print('   - Documents deleted: $deletedCount');
    print('   - Valid documents remaining: ${snapshot.docs.length - deletedCount}');
    print('🗑️  Successfully removed $deletedCount corrupted meal documents');
    
  } catch (error) {
    print('❌ Error during cleanup: $error');
    rethrow;
  }
} 