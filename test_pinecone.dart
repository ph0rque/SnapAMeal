import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Standalone test for Pinecone connectivity
/// Run with: dart test_pinecone.dart
void main() async {
  debugPrint('🔍 Testing Pinecone connection...\n');
  
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    
    final apiKey = dotenv.env['PINECONE_API_KEY'] ?? '';
    final indexName = dotenv.env['PINECONE_INDEX_NAME'] ?? 'snapameal-health-knowledge';
    
    if (apiKey.isEmpty) {
      debugPrint('❌ PINECONE_API_KEY not found in .env file');
      exit(1);
    }
    
    debugPrint('✅ API Key found: ${apiKey.substring(0, 10)}...');
    debugPrint('✅ Index Name: $indexName\n');
    
    // Step 1: List all indexes to see what exists
    debugPrint('📋 Listing all indexes...');
    final listResponse = await http.get(
      Uri.parse('https://api.pinecone.io/indexes'),
      headers: {
        'Api-Key': apiKey,
        'Content-Type': 'application/json',
        'X-Pinecone-API-Version': '2025-04',
      },
    );
    
    if (listResponse.statusCode == 200) {
      final indexes = jsonDecode(listResponse.body);
      debugPrint('✅ Successfully listed indexes:');
      for (var index in indexes['indexes'] ?? []) {
        debugPrint('   - ${index['name']} (${index['status']['state']})');
      }
      debugPrint('');
    } else {
      debugPrint('❌ Failed to list indexes: ${listResponse.statusCode}');
      debugPrint('Response: ${listResponse.body}\n');
    }
    
    // Step 2: Try to get specific index info
    debugPrint('🎯 Getting info for index: $indexName');
    final indexResponse = await http.get(
      Uri.parse('https://api.pinecone.io/indexes/$indexName'),
      headers: {
        'Api-Key': apiKey,
        'Content-Type': 'application/json',
        'X-Pinecone-API-Version': '2025-04',
      },
    );
    
    if (indexResponse.statusCode == 200) {
      final indexData = jsonDecode(indexResponse.body);
      debugPrint('✅ Index found successfully!');
      debugPrint('   Name: ${indexData['name']}');
      debugPrint('   Status: ${indexData['status']['state']}');
      debugPrint('   Host: ${indexData['host']}');
      debugPrint('   Dimension: ${indexData['dimension']}');
      debugPrint('   Metric: ${indexData['metric']}\n');
      
      // Step 3: Test connection to the index host
      final host = indexData['host'];
      if (host != null) {
        debugPrint('📊 Testing connection to index host...');
        final statsResponse = await http.post(
          Uri.parse('https://$host/describe_index_stats'),
          headers: {
            'Api-Key': apiKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({}),
        );
        
        if (statsResponse.statusCode == 200) {
          final stats = jsonDecode(statsResponse.body);
          debugPrint('✅ Index host connection successful!');
          debugPrint('   Total vectors: ${stats['total_vector_count'] ?? 0}');
          debugPrint('   Dimension: ${stats['dimension'] ?? 'N/A'}');
          debugPrint('   Namespaces: ${stats['namespaces']?.keys?.join(', ') ?? 'default'}');
        } else {
          debugPrint('❌ Index host connection failed: ${statsResponse.statusCode}');
          debugPrint('Response: ${statsResponse.body}');
        }
      }
    } else {
      debugPrint('❌ Index not found: ${indexResponse.statusCode}');
      debugPrint('Response: ${indexResponse.body}');
      
      if (indexResponse.statusCode == 404) {
        debugPrint('\n💡 Suggestion: Your index "$indexName" doesn\'t exist.');
        debugPrint('   Either create it in the Pinecone console or check the name.');
      }
    }
    
  } catch (e) {
    debugPrint('❌ Error during test: $e');
    exit(1);
  }
  
  debugPrint('\n🎉 Test completed!');
} 