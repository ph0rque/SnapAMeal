# Pinecone Vector Database Setup Guide

## Overview
This guide walks through setting up Pinecone vector database for SnapAMeal's Phase II health knowledge RAG system.

## Prerequisites
- Pinecone account (sign up at https://www.pinecone.io/)
- OpenAI API account for embeddings
- Flutter development environment

## Step 1: Create Pinecone Account and Index

### 1.1 Account Setup
1. Go to https://www.pinecone.io/ and create a free account
2. Verify your email and complete onboarding
3. Navigate to the Pinecone console

### 1.2 Create Index
1. Click "Create Index" in the Pinecone console
2. Use these settings:
   - **Index Name**: `snapameal-health-knowledge`
   - **Dimensions**: `1536` (for OpenAI text-embedding-3-small)
   - **Metric**: `cosine` 
   - **Environment**: `us-east1-gcp-free` (free tier)
   - **Pod Type**: `p1.x1` (starter)

### 1.3 Get API Key
1. Go to "API Keys" in the Pinecone console
2. Create a new API key or copy the default key
3. Save this key securely - you'll need it for environment variables

## Step 2: Environment Configuration

### 2.1 Create Environment File
Create a `.env` file in your project root (add to .gitignore):

```bash
# Pinecone Configuration
PINECONE_API_KEY=your_pinecone_api_key_here
PINECONE_ENVIRONMENT=us-east1-gcp-free
PINECONE_INDEX_NAME=snapameal-health-knowledge

# OpenAI Configuration  
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-4-turbo-preview
OPENAI_EMBEDDING_MODEL=text-embedding-3-small
```

### 2.2 Flutter Environment Setup
For Flutter, set environment variables when running:

```bash
# Development
flutter run --dart-define=PINECONE_API_KEY=your_key_here --dart-define=OPENAI_API_KEY=your_key_here

# Or create a launch configuration in VS Code
```

## Step 3: Index Schema Design

### 3.1 Vector Metadata Structure
Each vector in the index will have this metadata:
```json
{
  "id": "unique_document_id",
  "category": "nutrition|fitness|fasting|wellness|etc",
  "content_type": "tip|recipe|fact|quote|article",
  "source": "curated|user_generated|external_api",
  "tags": ["tag1", "tag2", "tag3"],
  "confidence_score": 0.95,
  "last_updated": "2025-01-XX",
  "user_preference_match": ["weight_loss", "fasting"]
}
```

### 3.2 Health Knowledge Categories
The system will organize content into these categories:
- **nutrition**: Macro/micro nutrients, food facts
- **fitness**: Exercise tips, workout advice  
- **fasting**: Intermittent fasting guidance
- **weight_loss**: Weight management strategies
- **meal_planning**: Recipe suggestions, meal prep
- **wellness**: General health and wellbeing
- **behavioral_health**: Motivation, habit formation
- **recipes**: Healthy recipe suggestions
- **supplements**: Vitamin and supplement info
- **hydration**: Water intake and hydration tips

## Step 4: Cost Optimization

### 4.1 Free Tier Limits
- **Pinecone Free**: 1 index, 100K vectors, 5 queries/sec
- **OpenAI**: Pay-per-use (monitor usage carefully)

### 4.2 Usage Monitoring
- Set up alerts in Pinecone console for usage limits
- Monitor OpenAI API usage in their dashboard
- Implement local caching to reduce API calls

### 4.3 Cost Control Strategies
- Use `text-embedding-3-small` (cheaper than `text-embedding-ada-002`)
- Batch embedding requests when possible
- Cache embeddings locally for repeated content
- Limit context length to 4000 tokens max

## Step 5: Testing the Setup

### 5.1 Connection Test
```dart
// Test in your Flutter app
import 'package:snapameal/config/ai_config.dart';

void testPineconeConnection() {
  print('Pinecone configured: ${AIConfig.isConfigured}');
  print('Base URL: ${AIConfig.pineconeBaseUrl}');
}
```

### 5.2 Verify Index
1. Go to Pinecone console
2. Check that your index appears in the dashboard  
3. Verify dimensions (1536) and metric (cosine) are correct

## Step 6: Security Considerations

### 6.1 API Key Security
- Never commit API keys to version control
- Use environment variables or secure secret management
- Rotate keys regularly
- Set up usage alerts

### 6.2 Access Control
- Use least-privilege API keys
- Monitor usage patterns for anomalies
- Consider IP whitelisting for production

## Next Steps
Once setup is complete, you can proceed to:
1. Implement the RAG service (`lib/services/rag_service.dart`)
2. Create health knowledge base seeding
3. Build vector retrieval system

## Troubleshooting

### Common Issues
- **"Index not found"**: Check index name matches exactly
- **"Unauthorized"**: Verify API key is correct and has proper permissions
- **"Dimension mismatch"**: Ensure embedding model matches index dimensions
- **Rate limiting**: Check if you've exceeded free tier limits

### Support Resources
- Pinecone Documentation: https://docs.pinecone.io/
- Pinecone Community: https://community.pinecone.io/
- OpenAI API Docs: https://platform.openai.com/docs/ 