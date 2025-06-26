import 'package:flutter/material.dart';
import '../services/rag_service.dart';
import '../services/openai_service.dart';

class DebugPineconePage extends StatefulWidget {
  const DebugPineconePage({super.key});

  @override
  State<DebugPineconePage> createState() => _DebugPineconePageState();
}

class _DebugPineconePageState extends State<DebugPineconePage> {
  late RAGService _ragService;
  bool _isLoading = false;
  Map<String, dynamic>? _testResults;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _ragService = RAGService(OpenAIService());
  }

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _testResults = null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Pinecone'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pinecone Connection Test',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testConnection,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Test Connection'),
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
                        
                        _buildStatusRow('Overall Success', _testResults!['success']),
                        _buildStatusRow('API Key Valid', _testResults!['api_key_valid']),
                        _buildStatusRow('Index Exists', _testResults!['index_exists']),
                        _buildStatusRow('Connection Test', _testResults!['connection_test']),
                        
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
                            style: TextStyle(
                              color: Colors.red.shade600,
                            ),
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
          Text('Namespaces: ${stats['namespaces']?.keys?.join(', ') ?? 'default'}'),
        ],
      ),
    );
  }
} 