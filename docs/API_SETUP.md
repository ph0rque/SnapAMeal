# API Setup Guide

This document explains how to set up the required API keys for SnapAMeal.

## Required API Keys

### 1. OpenAI API Key (Required for AI features)

1. Go to [OpenAI Platform](https://platform.openai.com/account/api-keys)
2. Sign in or create an account
3. Click "Create new secret key"
4. Copy the generated API key
5. Add it to your `.env` file (see below)

### 2. Pinecone API Key (Optional - for advanced RAG features)

1. Go to [Pinecone Console](https://app.pinecone.io/)
2. Sign in or create an account
3. Create a new index named `snapameal-health-knowledge`
4. Copy your API key from the dashboard
5. Add it to your `.env` file (see below)

### 3. MyFitnessPal API Key (Optional - for nutrition data integration)

1. Go to [MyFitnessPal Developer Portal](https://www.myfitnesspal.com/api)
2. Sign in or create an account
3. Register your application to get an API key
4. Copy the generated API key
5. Add it to your `.env` file (see below)

## Environment Configuration

Create a `.env` file in the root directory of the project with the following content:

```env
# Firebase Configuration (already configured for the project)
FIREBASE_PROJECT_ID=snapameal-cabc7
FIREBASE_STORAGE_BUCKET=snapameal-cabc7.appspot.com

# OpenAI Configuration (REQUIRED)
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-4-turbo-preview
OPENAI_EMBEDDING_MODEL=text-embedding-3-small

# Pinecone Configuration (OPTIONAL)
PINECONE_API_KEY=your_pinecone_api_key_here
PINECONE_ENVIRONMENT=us-east1-gcp-free
PINECONE_INDEX_NAME=snapameal-health-knowledge

# MyFitnessPal Configuration (OPTIONAL)
MYFITNESSPAL_API_KEY=your_myfitnesspal_api_key_here
```

## What happens without API keys?

- **Without OpenAI API Key**: AI features will be disabled but the app will still work for basic functionality like meal logging, fasting tracking, and social features.
- **Without Pinecone API Key**: Advanced RAG-powered health insights will be disabled, but basic AI advice will still work.
- **Without MyFitnessPal API Key**: Nutrition data integration will be disabled, but manual meal logging will still work.

## Security Notes

- Never commit your `.env` file to version control
- The `.env` file is already added to `.gitignore`
- Keep your API keys secure and don't share them
- Consider using environment-specific keys for development vs production

## Testing

After adding your API keys:

1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter run`

The app should now work without API key errors in the debug console. 