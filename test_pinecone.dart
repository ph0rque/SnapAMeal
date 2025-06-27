import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:snapameal/utils/logger.dart';

/// Standalone test for Pinecone connectivity
/// Run with: dart test_pinecone.dart
void main() async {
  Logger.i('🔍 Testing Pinecone connection...\n');
  
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    
    final apiKey = dotenv.env['PINECONE_API_KEY'] ?? '';
    final indexName = dotenv.env['PINECONE_INDEX_NAME'] ?? 'snapameal-health-knowledge';
    
    if (apiKey.isEmpty) {
      Logger.i('❌ PINECONE_API_KEY not found in .env file');
      exit(1);
    }
    
    Logger.i('✅ API Key found: ${apiKey.substring(0, 10)}...');
    Logger.i('✅ Index Name: $indexName\n');
    
    // Step 1: List all indexes to see what exists
    Logger.i('📋 Listing all indexes...');
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
      Logger.i('✅ Successfully listed indexes:');
      for (var index in indexes['indexes'] ?? []) {
        Logger.i('   - ${index['name']} (${index['status']['state']})');
      }
      Logger.i('');
    } else {
      Logger.i('❌ Failed to list indexes: ${listResponse.statusCode}');
      Logger.i('Response: ${listResponse.body}\n');
    }
    
    // Step 2: Try to get specific index info
    Logger.i('🎯 Getting info for index: $indexName');
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
      Logger.i('✅ Index found successfully!');
      Logger.i('   Name: ${indexData['name']}');
      Logger.i('   Status: ${indexData['status']['state']}');
      Logger.i('   Host: ${indexData['host']}');
      Logger.i('   Dimension: ${indexData['dimension']}');
      Logger.i('   Metric: ${indexData['metric']}\n');
      
      // Step 3: Test connection to the index host
      final host = indexData['host'];
      if (host != null) {
        Logger.i('📊 Testing connection to index host...');
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
          Logger.i('✅ Index host connection successful!');
          Logger.i('   Total vectors: ${stats['total_vector_count'] ?? 0}');
          Logger.i('   Dimension: ${stats['dimension'] ?? 'N/A'}');
          Logger.i('   Namespaces: ${stats['namespaces']?.keys?.join(', ') ?? 'default'}');
        } else {
          Logger.i('❌ Index host connection failed: ${statsResponse.statusCode}');
          Logger.i('Response: ${statsResponse.body}');
        }
      }
    } else {
      Logger.i('❌ Index not found: ${indexResponse.statusCode}');
      Logger.i('Response: ${indexResponse.body}');
      
      if (indexResponse.statusCode == 404) {
        Logger.i('\n💡 Suggestion: Your index "$indexName" doesn\'t exist.');
        Logger.i('   Either create it in the Pinecone console or check the name.');
      }
    }
    
  } catch (e) {
    Logger.i('❌ Error during test: $e');
    exit(1);
  }
  
  Logger.i('\n🎉 Test completed!');
} 