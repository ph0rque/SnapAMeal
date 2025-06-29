const admin = require('firebase-admin');
const https = require('https');
require('dotenv').config({ path: '../.env' });

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'snapameal-cabc7'
});

const db = admin.firestore();

// API Configuration
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const PINECONE_API_KEY = process.env.PINECONE_API_KEY;
const PINECONE_INDEX_NAME = process.env.PINECONE_INDEX_NAME || 'snapameal-health-knowledge';
const PINECONE_BASE_URL = 'https://api.pinecone.io';
const OPENAI_BASE_URL = 'https://api.openai.com/v1';

if (!OPENAI_API_KEY || !PINECONE_API_KEY) {
  console.error('❌ Missing required API keys in environment variables');
  console.log('   Required: OPENAI_API_KEY, PINECONE_API_KEY');
  process.exit(1);
}

let pineconeIndexHost = null;

async function makeOpenAIRequest(text) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify({
      input: text,
      model: 'text-embedding-3-small'
    });

    const options = {
      hostname: 'api.openai.com',
      port: 443,
      path: '/v1/embeddings',
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${OPENAI_API_KEY}`,
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data)
      }
    };

    const req = https.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        try {
          const parsed = JSON.parse(responseData);
          if (parsed.data && parsed.data[0] && parsed.data[0].embedding) {
            resolve(parsed.data[0].embedding);
          } else {
            reject(new Error(`Invalid OpenAI response: ${responseData}`));
          }
        } catch (error) {
          reject(new Error(`Failed to parse OpenAI response: ${error.message}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(data);
    req.end();
  });
}

async function makePineconeRequest(path, method = 'GET', data = null) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.pinecone.io',
      port: 443,
      path: path,
      method: method,
      headers: {
        'Api-Key': PINECONE_API_KEY,
        'Content-Type': 'application/json',
        'X-Pinecone-API-Version': '2025-04'
      }
    };

    if (data) {
      const jsonData = JSON.stringify(data);
      options.headers['Content-Length'] = Buffer.byteLength(jsonData);
    }

    const req = https.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        try {
          const parsed = responseData ? JSON.parse(responseData) : {};
          resolve({
            statusCode: res.statusCode,
            data: parsed
          });
        } catch (error) {
          resolve({
            statusCode: res.statusCode,
            data: responseData
          });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

async function makePineconeIndexRequest(path, method = 'POST', data = null) {
  if (!pineconeIndexHost) {
    throw new Error('Pinecone index host not initialized');
  }

  return new Promise((resolve, reject) => {
    const options = {
      hostname: pineconeIndexHost.replace('https://', ''),
      port: 443,
      path: path,
      method: method,
      headers: {
        'Api-Key': PINECONE_API_KEY,
        'Content-Type': 'application/json'
      }
    };

    if (data) {
      const jsonData = JSON.stringify(data);
      options.headers['Content-Length'] = Buffer.byteLength(jsonData);
    }

    const req = https.request(options, (res) => {
      let responseData = '';
      
      res.on('data', (chunk) => {
        responseData += chunk;
      });
      
      res.on('end', () => {
        try {
          const parsed = responseData ? JSON.parse(responseData) : {};
          resolve({
            statusCode: res.statusCode,
            data: parsed
          });
        } catch (error) {
          resolve({
            statusCode: res.statusCode,
            data: responseData
          });
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

async function initializePinecone() {
  console.log('🔧 Initializing Pinecone connection...');
  
  try {
    // Get index information
    const response = await makePineconeRequest(`/indexes/${PINECONE_INDEX_NAME}`);
    
    if (response.statusCode === 200 && response.data.host) {
      pineconeIndexHost = response.data.host;
      console.log(`✅ Pinecone index host: ${pineconeIndexHost}`);
      
      // Test connection to index
      const statsResponse = await makePineconeIndexRequest('/describe_index_stats', 'POST', {});
      
      if (statsResponse.statusCode === 200) {
        const stats = statsResponse.data;
        console.log(`✅ Current index stats:`);
        console.log(`   Total vectors: ${stats.totalVectorCount || 0}`);
        console.log(`   Dimension: ${stats.dimension || 'N/A'}`);
        console.log(`   Index fullness: ${stats.indexFullness || 0}`);
        return true;
      } else {
        console.error(`❌ Failed to get index stats: ${statsResponse.statusCode}`);
        return false;
      }
    } else {
      console.error(`❌ Failed to get index info: ${response.statusCode}`);
      if (response.statusCode === 404) {
        console.log(`💡 Index "${PINECONE_INDEX_NAME}" not found. Please create it in Pinecone console.`);
      }
      return false;
    }
  } catch (error) {
    console.error(`❌ Error initializing Pinecone: ${error.message}`);
    return false;
  }
}

function generateKnowledgeContent(food) {
  const nutrition = food.nutritionPer100g || {};
  const calories = nutrition.calories || 0;
  const protein = nutrition.protein || 0;
  const carbs = nutrition.carbs || 0;
  const fat = nutrition.fat || 0;
  const fiber = nutrition.fiber || 0;
  const vitamins = nutrition.vitamins || {};
  const minerals = nutrition.minerals || {};
  
  let content = `${food.foodName} is a ${food.category} with ${calories} calories per 100g.

Nutritional Profile:
- Protein: ${protein.toFixed(1)}g
- Carbohydrates: ${carbs.toFixed(1)}g
- Fat: ${fat.toFixed(1)}g`;

  if (fiber > 0) {
    content += `\n- Fiber: ${fiber.toFixed(1)}g`;
  }

  if (Object.keys(vitamins).length > 0) {
    content += `\n\nVitamins:`;
    Object.entries(vitamins).forEach(([vitamin, amount]) => {
      content += `\n- Vitamin ${vitamin}: ${amount}mg`;
    });
  }

  if (Object.keys(minerals).length > 0) {
    content += `\n\nMinerals:`;
    Object.entries(minerals).forEach(([mineral, amount]) => {
      content += `\n- ${mineral.charAt(0).toUpperCase() + mineral.slice(1)}: ${amount}mg`;
    });
  }

  // Add health benefits based on category and nutrients
  content += `\n\nHealth Benefits:`;
  
  if (protein > 15) {
    content += `\n- High protein content supports muscle building and repair`;
  }
  
  if (fiber > 6) {
    content += `\n- Excellent source of dietary fiber for digestive health`;
  }
  
  if (vitamins.C > 20) {
    content += `\n- Rich in Vitamin C for immune system support`;
  }
  
  switch (food.category) {
    case 'fruits':
      content += `\n- Natural source of vitamins and antioxidants`;
      content += `\n- Provides natural energy from healthy sugars`;
      break;
    case 'vegetables':
      content += `\n- Rich in vitamins, minerals, and phytonutrients`;
      content += `\n- Low in calories, high in nutrients`;
      break;
    case 'proteins':
      content += `\n- Essential amino acids for body function`;
      content += `\n- Supports muscle maintenance and growth`;
      break;
    case 'grains':
      content += `\n- Provides sustained energy from complex carbohydrates`;
      content += `\n- Source of B vitamins and minerals`;
      break;
    case 'dairy':
      content += `\n- Good source of calcium for bone health`;
      content += `\n- Provides high-quality protein`;
      break;
  }

  // Add serving suggestions
  const servingSizes = food.servingSizes || {};
  if (Object.keys(servingSizes).length > 0) {
    content += `\n\nServing Suggestions:`;
    Object.entries(servingSizes).forEach(([serving, grams]) => {
      const servingCalories = Math.round((calories * grams) / 100);
      content += `\n- ${serving} (${grams}g): ${servingCalories} calories`;
    });
  }

  return content;
}

async function fetchAllFoods() {
  console.log('📋 Fetching all foods from Firebase...');
  
  try {
    const snapshot = await db.collection('foods').get();
    const foods = [];
    
    snapshot.forEach(doc => {
      const data = doc.data();
      foods.push({
        id: doc.id,
        ...data
      });
    });
    
    console.log(`✅ Found ${foods.length} foods in Firebase`);
    return foods;
  } catch (error) {
    console.error(`❌ Error fetching foods: ${error.message}`);
    return [];
  }
}

async function createKnowledgeDocument(food) {
  try {
    const content = generateKnowledgeContent(food);
    const title = `Nutritional Information: ${food.foodName}`;
    
    // Generate embedding
    console.log(`   Generating embedding for: ${food.foodName}`);
    const embedding = await makeOpenAIRequest(`${title}\n\n${content}`);
    
    // Create metadata
    const metadata = {
      title: title,
      food_name: food.foodName,
      category: food.category || 'other',
      subcategory: food.subcategory || '',
      source: food.source || 'USDA',
      fdc_id: food.fdcId || 0,
      calories_per_100g: food.nutritionPer100g?.calories || 0,
      protein_per_100g: food.nutritionPer100g?.protein || 0,
      data_type: 'nutrition_facts',
      content_type: 'food_profile',
      tags: food.searchableKeywords || [],
      allergens: food.allergens || [],
      confidence_score: 0.95,
      indexed_at: new Date().toISOString()
    };
    
    return {
      id: `food_${food.id}`,
      values: embedding,
      metadata: metadata
    };
  } catch (error) {
    console.error(`❌ Error creating knowledge document for ${food.foodName}: ${error.message}`);
    return null;
  }
}

async function upsertVectorsBatch(vectors) {
  try {
    const response = await makePineconeIndexRequest('/vectors/upsert', 'POST', {
      vectors: vectors,
      namespace: 'default'
    });
    
    return response.statusCode === 200;
  } catch (error) {
    console.error(`❌ Error upserting vectors: ${error.message}`);
    return false;
  }
}

async function migrateFoodsToPinecone() {
  console.log('🍎 Starting Foods to Pinecone Migration...');
  console.log('🎯 Migrating comprehensive USDA food database for RAG functionality\n');
  
  try {
    // Step 1: Initialize Pinecone
    const pineconeReady = await initializePinecone();
    if (!pineconeReady) {
      console.error('❌ Pinecone initialization failed');
      return;
    }
    
    // Step 2: Fetch all foods from Firebase
    const foods = await fetchAllFoods();
    if (foods.length === 0) {
      console.error('❌ No foods found in Firebase');
      return;
    }
    
    // Step 3: Process foods into knowledge documents
    console.log('\n🔄 Processing foods into knowledge documents...');
    const knowledgeVectors = [];
    let processedCount = 0;
    let errorCount = 0;
    
    for (const food of foods) {
      try {
        const vector = await createKnowledgeDocument(food);
        if (vector) {
          knowledgeVectors.push(vector);
          processedCount++;
        } else {
          errorCount++;
        }
        
        // Progress update
        if ((processedCount + errorCount) % 10 === 0) {
          console.log(`   Progress: ${processedCount + errorCount}/${foods.length} foods processed`);
        }
        
        // Rate limiting delay
        await new Promise(resolve => setTimeout(resolve, 100));
        
      } catch (error) {
        console.error(`❌ Error processing ${food.foodName}: ${error.message}`);
        errorCount++;
      }
    }
    
    console.log(`\n📊 Processing Summary:`);
    console.log(`   Successfully processed: ${processedCount} foods`);
    console.log(`   Errors: ${errorCount} foods`);
    console.log(`   Success rate: ${((processedCount / foods.length) * 100).toFixed(1)}%`);
    
    // Step 4: Upload to Pinecone in batches
    console.log('\n⬆️  Uploading vectors to Pinecone...');
    const batchSize = 100; // Pinecone batch limit
    let uploadedCount = 0;
    
    for (let i = 0; i < knowledgeVectors.length; i += batchSize) {
      const batch = knowledgeVectors.slice(i, i + batchSize);
      
      console.log(`   Uploading batch ${Math.floor(i / batchSize) + 1}/${Math.ceil(knowledgeVectors.length / batchSize)} (${batch.length} vectors)...`);
      
      const success = await upsertVectorsBatch(batch);
      if (success) {
        uploadedCount += batch.length;
        console.log(`   ✅ Batch uploaded successfully`);
      } else {
        console.log(`   ❌ Batch upload failed`);
      }
      
      // Rate limiting delay between batches
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
    
    // Step 5: Verify final state
    console.log('\n📊 Getting final index statistics...');
    const finalStatsResponse = await makePineconeIndexRequest('/describe_index_stats', 'POST', {});
    
    if (finalStatsResponse.statusCode === 200) {
      const stats = finalStatsResponse.data;
      console.log(`\n🎉 Migration completed successfully!`);
      console.log(`📊 Final Statistics:`);
      console.log(`   Foods processed: ${processedCount}/${foods.length}`);
      console.log(`   Vectors uploaded: ${uploadedCount}/${knowledgeVectors.length}`);
      console.log(`   Total vectors in index: ${stats.totalVectorCount || 0}`);
      console.log(`   Index dimension: ${stats.dimension || 'N/A'}`);
      console.log(`   Index fullness: ${((stats.indexFullness || 0) * 100).toFixed(2)}%`);
      
      // Show category breakdown
      const categories = {};
      foods.forEach(food => {
        const category = food.category || 'other';
        categories[category] = (categories[category] || 0) + 1;
      });
      
      console.log(`\n🏷️  Foods by category:`);
      Object.entries(categories)
        .sort(([,a], [,b]) => b - a)
        .forEach(([category, count]) => {
          console.log(`   ${category}: ${count} foods`);
        });
        
      console.log(`\n✅ RAG system is now ready with comprehensive food knowledge!`);
      console.log(`🔍 Users can now ask natural language questions about nutrition and get AI-powered answers.`);
      
    } else {
      console.error(`❌ Failed to get final stats: ${finalStatsResponse.statusCode}`);
    }
    
  } catch (error) {
    console.error(`❌ Migration failed: ${error.message}`);
    process.exit(1);
  }
  
  process.exit(0);
}

migrateFoodsToPinecone(); 