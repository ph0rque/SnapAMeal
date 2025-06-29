import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/rag_service.dart';
import '../services/openai_service.dart';
import '../services/knowledge_seeding_service.dart';

class DebugPineconePage extends StatefulWidget {
  const DebugPineconePage({super.key});

  @override
  State<DebugPineconePage> createState() => _DebugPineconePageState();
}

class _DebugPineconePageState extends State<DebugPineconePage> {
  late RAGService _ragService;
  late KnowledgeSeedingService _seedingService;
  bool _isLoading = false;
  bool _isSeeding = false;
  bool _isCleaningUp = false;
  Map<String, dynamic>? _testResults;
  Map<String, dynamic>? _seedingResults;
  Map<String, dynamic>? _cleanupResults;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _ragService = RAGService(OpenAIService());
    _seedingService = KnowledgeSeedingService(_ragService);
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _testResults = null;
      _seedingResults = null;
      _cleanupResults = null;
      _errorMessage = null;
    });

    try {
      final results = await _ragService.testConnectionWithDetails();
      setState(() {
        _testResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _seedKnowledgeBase() async {
    setState(() {
      _isSeeding = true;
      _seedingResults = null;
      _cleanupResults = null;
      _errorMessage = null;
    });

    try {
      // First test connection
      final connectionTest = await _ragService.testConnection();
      if (!connectionTest) {
        throw Exception('Pinecone connection failed. Please test connection first.');
      }

      // Perform the seeding
      final success = await _seedingService.seedKnowledgeBase();
      
      if (success) {
        // Get updated stats after seeding
        final stats = await _ragService.getKnowledgeBaseStats();
        
        setState(() {
          _seedingResults = {
            'success': true,
            'message': 'Knowledge base seeded successfully!',
            'stats': stats,
          };
          _isSeeding = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to seed knowledge base';
          _isSeeding = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error seeding knowledge base: $e';
        _isSeeding = false;
      });
    }
  }

  Future<void> _cleanupCorruptedMealLogs() async {
    setState(() {
      _isCleaningUp = true;
      _cleanupResults = null;
      _errorMessage = null;
    });

    try {
      print('🧹 Starting cleanup of corrupted meal logs...');
      
      final firestore = FirebaseFirestore.instance;
      
      // Get current user ID from Firebase Auth
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      final currentUserId = currentUser.uid;
      print('👤 Current user ID: $currentUserId');
      
      int totalChecked = 0;
      int corruptedCount = 0;
      int deletedCount = 0;
      final List<DocumentReference> corruptedDocs = [];
      
      // Step 1: Check user's own meal logs
      print('📊 Step 1: Fetching meal documents for current user...');
      final QuerySnapshot userSnapshot = await firestore
          .collection('meal_logs')
          .where('user_id', isEqualTo: currentUserId)
          .get();
      
      print('📊 Found ${userSnapshot.docs.length} meal documents for current user');
      totalChecked += userSnapshot.docs.length;
      
      // Check user's documents for corruption
      for (final doc in userSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Check if document is corrupted (has null/empty values for critical fields)
        final bool isCorrupted = (
          data['image_url'] == null || 
          data['image_url'] == '' ||
          data['image_path'] == null || 
          data['image_path'] == ''
        );
        
        if (isCorrupted) {
          corruptedCount++;
          print('🗑️  Found corrupted user document: ${doc.id}');
          print('   - image_url: ${data['image_url']}');
          print('   - image_path: ${data['image_path']}');
          print('   - user_id: ${data['user_id']}');
          
          corruptedDocs.add(doc.reference);
        }
      }
      
      // Step 2: Check for orphaned documents (null user_id)
      print('📊 Step 2: Fetching orphaned meal documents (null user_id)...');
      try {
        final QuerySnapshot orphanedSnapshot = await firestore
            .collection('meal_logs')
            .where('user_id', isNull: true)
            .get();
        
        print('📊 Found ${orphanedSnapshot.docs.length} orphaned meal documents');
        totalChecked += orphanedSnapshot.docs.length;
        
        // All orphaned documents are considered corrupted
        for (final doc in orphanedSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          corruptedCount++;
          print('🗑️  Found orphaned document: ${doc.id}');
          print('   - image_url: ${data['image_url']}');
          print('   - image_path: ${data['image_path']}');
          print('   - user_id: ${data['user_id']}');
          
          corruptedDocs.add(doc.reference);
        }
      } catch (e) {
        print('⚠️  Could not query orphaned documents: $e');
        // Continue with user documents only
      }
      
      // Step 3: Check for documents with empty string user_id
      print('📊 Step 3: Fetching documents with empty user_id...');
      try {
        final QuerySnapshot emptyUserSnapshot = await firestore
            .collection('meal_logs')
            .where('user_id', isEqualTo: '')
            .get();
        
        print('📊 Found ${emptyUserSnapshot.docs.length} documents with empty user_id');
        totalChecked += emptyUserSnapshot.docs.length;
        
        // All empty user_id documents are considered corrupted
        for (final doc in emptyUserSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          corruptedCount++;
          print('🗑️  Found empty user_id document: ${doc.id}');
          print('   - image_url: ${data['image_url']}');
          print('   - image_path: ${data['image_path']}');
          print('   - user_id: "${data['user_id']}"');
          
          corruptedDocs.add(doc.reference);
        }
      } catch (e) {
        print('⚠️  Could not query empty user_id documents: $e');
        // Continue with what we have
      }
      
      if (corruptedDocs.isEmpty) {
        setState(() {
          _cleanupResults = {
            'success': true,
            'message': 'No corrupted documents found - database is clean!',
            'totalChecked': totalChecked,
            'corruptedFound': 0,
            'documentsDeleted': 0,
            'validRemaining': totalChecked,
          };
          _isCleaningUp = false;
        });
        return;
      }
      
      print('\n🗑️  Deleting ${corruptedDocs.length} corrupted documents...');
      
      // Delete documents one by one to handle permission differences
      for (int i = 0; i < corruptedDocs.length; i++) {
        try {
          print('💾 Deleting document ${i + 1}/${corruptedDocs.length}: ${corruptedDocs[i].id}');
          await corruptedDocs[i].delete();
          deletedCount++;
        } catch (e) {
          print('❌ Failed to delete document ${corruptedDocs[i].id}: $e');
          // Continue with next document - some may fail due to permissions
        }
      }
      
      setState(() {
        _cleanupResults = {
          'success': true,
          'message': 'Cleanup completed! Removed $deletedCount out of $corruptedCount corrupted meal documents.',
          'totalChecked': totalChecked,
          'corruptedFound': corruptedCount,
          'documentsDeleted': deletedCount,
          'validRemaining': totalChecked - deletedCount,
        };
        _isCleaningUp = false;
      });
      
      print('✅ Cleanup completed successfully!');
      print('📊 Summary:');
      print('   - Total documents checked: $totalChecked');
      print('   - Corrupted documents found: $corruptedCount');
      print('   - Documents deleted: $deletedCount');
      print('   - Valid documents remaining: ${totalChecked - deletedCount}');
      
    } catch (e) {
      print('❌ Error during cleanup: $e');
      setState(() {
        _errorMessage = 'Error cleaning up meal logs: $e';
        _isCleaningUp = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug & Cleanup'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pinecone Connection & Knowledge Base',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Connection Test Button
            ElevatedButton(
              onPressed: (_isLoading || _isSeeding || _isCleaningUp) ? null : _testConnection,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Test Connection'),
            ),

            const SizedBox(height: 12),

            // Seed Knowledge Base Button
            ElevatedButton(
              onPressed: (_isLoading || _isSeeding || _isCleaningUp) ? null : _seedKnowledgeBase,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: _isSeeding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Seed Knowledge Base'),
            ),

            const SizedBox(height: 24),

            const Text(
              'Meal Log Cleanup',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Cleanup Corrupted Meal Logs Button
            ElevatedButton(
              onPressed: (_isLoading || _isSeeding || _isCleaningUp) ? null : _cleanupCorruptedMealLogs,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: _isCleaningUp
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Cleanup Corrupted Meal Logs'),
            ),

            const SizedBox(height: 24),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Error:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),

            if (_seedingResults != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seeding Results:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _seedingResults!['message'],
                      style: const TextStyle(color: Colors.green),
                    ),
                    if (_seedingResults!['stats'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Updated Stats - Total Vectors: ${_seedingResults!['stats']['total_vector_count']}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            if (_cleanupResults != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meal Log Cleanup Results:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _cleanupResults!['message'],
                      style: const TextStyle(color: Colors.blue),
                    ),
                    if (_cleanupResults!['totalChecked'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Total documents checked: ${_cleanupResults!['totalChecked']}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Corrupted documents found: ${_cleanupResults!['corruptedFound']}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Documents deleted: ${_cleanupResults!['documentsDeleted']}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Valid documents remaining: ${_cleanupResults!['validRemaining']}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            if (_testResults != null)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Test Results:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _buildStatusRow(
                          'Overall Success',
                          _testResults!['success'],
                        ),
                        _buildStatusRow(
                          'API Key Valid',
                          _testResults!['api_key_valid'],
                        ),
                        _buildStatusRow(
                          'Index Exists',
                          _testResults!['index_exists'],
                        ),
                        _buildStatusRow(
                          'Connection Test',
                          _testResults!['connection_test'],
                        ),

                        if (_testResults!['index_host'] != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Index Host:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            _testResults!['index_host'],
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],

                        if (_testResults!['index_stats'] != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Index Statistics:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildStatsInfo(_testResults!['index_stats']),
                        ],

                        if (_testResults!['error'] != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Error Details:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _testResults!['error'],
                            style: TextStyle(color: Colors.red.shade600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.error,
            color: status ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          Text(
            status ? 'PASS' : 'FAIL',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: status ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsInfo(Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Vectors: ${stats['totalVectorCount'] ?? 0}'),
          Text('Dimension: ${stats['dimension'] ?? 'N/A'}'),
          Text('Index Fullness: ${stats['indexFullness'] ?? 0}'),
          Text(
            'Namespaces: ${stats['namespaces']?.keys?.join(', ') ?? 'default'}',
          ),
        ],
      ),
    );
  }
}
