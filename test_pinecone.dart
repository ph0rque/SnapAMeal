import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Standalone test for Pinecone connectivity
/// Run with: dart test_pinecone.dart
void main() async {
  print('🔍 Testing Pinecone connection...\n');
  
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    
    final apiKey = dotenv.env['PINECONE_API_KEY'] ?? '';
    final indexName = dotenv.env['PINECONE_INDEX_NAME'] ?? 'snapameal-health-knowledge';
    
    if (apiKey.isEmpty) {
      print('❌ PINECONE_API_KEY not found in .env file');
      exit(1);
    }
    
    print('✅ API Key found: ${apiKey.substring(0, 10)}...');
    print('✅ Index Name: $indexName\n');
    
    // Step 1: List all indexes to see what exists
    print('📋 Listing all indexes...');
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
      print('✅ Successfully listed indexes:');
      for (var index in indexes['indexes'] ?? []) {
        print('   - ${index['name']} (${index['status']['state']})');
      }
      print('');
    } else {
      print('❌ Failed to list indexes: ${listResponse.statusCode}');
      print('Response: ${listResponse.body}\n');
    }
    
    // Step 2: Try to get specific index info
    print('🎯 Getting info for index: $indexName');
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
      print('✅ Index found successfully!');
      print('   Name: ${indexData['name']}');
      print('   Status: ${indexData['status']['state']}');
      print('   Host: ${indexData['host']}');
      print('   Dimension: ${indexData['dimension']}');
      print('   Metric: ${indexData['metric']}\n');
      
      // Step 3: Test connection to the index host
      final host = indexData['host'];
      if (host != null) {
        print('📊 Testing connection to index host...');
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
          print('✅ Index host connection successful!');
          print('   Total vectors: ${stats['total_vector_count'] ?? 0}');
          print('   Dimension: ${stats['dimension'] ?? 'N/A'}');
          print('   Namespaces: ${stats['namespaces']?.keys?.join(', ') ?? 'default'}');
        } else {
          print('❌ Index host connection failed: ${statsResponse.statusCode}');
          print('Response: ${statsResponse.body}');
        }
      }
    } else {
      print('❌ Index not found: ${indexResponse.statusCode}');
      print('Response: ${indexResponse.body}');
      
      if (indexResponse.statusCode == 404) {
        print('\n💡 Suggestion: Your index "$indexName" doesn\'t exist.');
        print('   Either create it in the Pinecone console or check the name.');
      }
    }
    
  } catch (e) {
    print('❌ Error during test: $e');
    exit(1);
  }
  
  print('\n🎉 Test completed!');
} 