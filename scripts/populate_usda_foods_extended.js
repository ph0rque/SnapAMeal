const admin = require('firebase-admin');
const https = require('https');
require('dotenv').config({ path: '../.env' });

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'snapameal-cabc7'
});

const db = admin.firestore();

// USDA API Configuration
const USDA_API_KEY = process.env.USDA_API_KEY;
const USDA_BASE_URL = 'https://api.nal.usda.gov/fdc/v1';

if (!USDA_API_KEY) {
  console.error('❌ USDA_API_KEY not found in environment variables');
  console.log('   Please add USDA_API_KEY to your .env file');
  process.exit(1);
}

// Comprehensive search terms for 200+ foods
const SEARCH_CATEGORIES = [
  // Fruits (40+ varieties)
  { term: 'apple', count: 8 },
  { term: 'banana', count: 6 },
  { term: 'orange', count: 6 },
  { term: 'strawberry', count: 5 },
  { term: 'blueberry', count: 5 },
  { term: 'grape', count: 5 },
  { term: 'peach', count: 4 },
  { term: 'pear', count: 4 },
  { term: 'cherry', count: 4 },
  { term: 'pineapple', count: 3 },
  { term: 'mango', count: 3 },
  { term: 'kiwi', count: 3 },
  
  // Vegetables (50+ varieties)
  { term: 'broccoli', count: 5 },
  { term: 'spinach', count: 5 },
  { term: 'carrot', count: 5 },
  { term: 'tomato', count: 6 },
  { term: 'potato', count: 8 },
  { term: 'onion', count: 5 },
  { term: 'pepper', count: 6 },
  { term: 'lettuce', count: 4 },
  { term: 'cucumber', count: 4 },
  { term: 'celery', count: 3 },
  { term: 'cauliflower', count: 3 },
  { term: 'cabbage', count: 3 },
  { term: 'mushroom', count: 5 },
  { term: 'zucchini', count: 3 },
  
  // Proteins (60+ varieties)
  { term: 'chicken', count: 10 },
  { term: 'beef', count: 10 },
  { term: 'pork', count: 8 },
  { term: 'fish', count: 8 },
  { term: 'salmon', count: 5 },
  { term: 'tuna', count: 5 },
  { term: 'egg', count: 5 },
  { term: 'turkey', count: 6 },
  { term: 'shrimp', count: 4 },
  { term: 'crab', count: 3 },
  { term: 'lamb', count: 4 },
  
  // Grains & Cereals (30+ varieties)
  { term: 'rice', count: 8 },
  { term: 'bread', count: 8 },
  { term: 'pasta', count: 6 },
  { term: 'oats', count: 5 },
  { term: 'quinoa', count: 4 },
  { term: 'barley', count: 3 },
  { term: 'wheat', count: 5 },
  { term: 'cereal', count: 6 },
  
  // Dairy (25+ varieties)
  { term: 'milk', count: 6 },
  { term: 'cheese', count: 8 },
  { term: 'yogurt', count: 6 },
  { term: 'butter', count: 3 },
  { term: 'cream', count: 4 },
  
  // Nuts & Seeds (25+ varieties)
  { term: 'almond', count: 4 },
  { term: 'walnut', count: 3 },
  { term: 'peanut', count: 4 },
  { term: 'cashew', count: 3 },
  { term: 'pistachio', count: 3 },
  { term: 'sunflower seed', count: 3 },
  { term: 'pumpkin seed', count: 2 },
  { term: 'pecan', count: 3 },
  
  // Legumes (20+ varieties)
  { term: 'beans', count: 8 },
  { term: 'lentils', count: 4 },
  { term: 'chickpeas', count: 3 },
  { term: 'peas', count: 4 },
  { term: 'soybeans', count: 3 }
];

async function makeUSDARequest(endpoint, params = {}) {
  return new Promise((resolve, reject) => {
    const queryParams = new URLSearchParams({
      api_key: USDA_API_KEY,
      ...params
    });
    
    const url = `${USDA_BASE_URL}${endpoint}?${queryParams}`;
    
    https.get(url, (res) => {
      let data = '';
      
      res.on('data', (chunk) => {
        data += chunk;
      });
      
      res.on('end', () => {
        try {
          const jsonData = JSON.parse(data);
          resolve(jsonData);
        } catch (error) {
          reject(new Error(`Failed to parse JSON: ${error.message}`));
        }
      });
    }).on('error', (error) => {
      reject(error);
    });
  });
}

async function searchFoods(query, pageSize = 50) {
  try {
    const response = await makeUSDARequest('/foods/search', {
      query: query,
      dataType: 'Foundation,SR Legacy',
      pageSize: pageSize,
      pageNumber: 1,
      sortBy: 'dataType.keyword',
      sortOrder: 'asc'
    });
    
    return response.foods || [];
  } catch (error) {
    console.error(`❌ Error searching for ${query}:`, error.message);
    return [];
  }
}

function transformUSDAFood(usdaFood) {
  try {
    const foodName = usdaFood.description || 'Unknown Food';
    const fdcId = usdaFood.fdcId;
    const dataType = usdaFood.dataType?.toLowerCase() || 'foundation';
    
    // Extract nutrients
    const nutrients = {};
    const vitamins = {};
    const minerals = {};
    
    if (usdaFood.foodNutrients) {
      for (const nutrient of usdaFood.foodNutrients) {
        const name = nutrient.nutrient?.name?.toLowerCase() || '';
        const value = nutrient.amount || 0;
        
        // Map common nutrients
        if (name.includes('energy') || name.includes('calorie')) {
          nutrients.calories = Math.round(value);
        } else if (name.includes('protein')) {
          nutrients.protein = parseFloat(value.toFixed(2));
        } else if (name.includes('carbohydrate')) {
          nutrients.carbs = parseFloat(value.toFixed(2));
        } else if (name.includes('total lipid') || name === 'fat') {
          nutrients.fat = parseFloat(value.toFixed(2));
        } else if (name.includes('fiber')) {
          nutrients.fiber = parseFloat(value.toFixed(2));
        } else if (name.includes('sugars')) {
          nutrients.sugar = parseFloat(value.toFixed(2));
        } else if (name.includes('saturated')) {
          nutrients.saturatedFat = parseFloat(value.toFixed(2));
        } else if (name.includes('cholesterol')) {
          nutrients.cholesterol = parseFloat(value.toFixed(2));
        } else if (name.includes('sodium')) {
          minerals.sodium = parseFloat(value.toFixed(2));
        } else if (name.includes('potassium')) {
          minerals.potassium = parseFloat(value.toFixed(2));
        } else if (name.includes('calcium')) {
          minerals.calcium = parseFloat(value.toFixed(2));
        } else if (name.includes('iron')) {
          minerals.iron = parseFloat(value.toFixed(2));
        } else if (name.includes('vitamin c')) {
          vitamins.C = parseFloat(value.toFixed(1));
        } else if (name.includes('vitamin a')) {
          vitamins.A = parseFloat(value.toFixed(1));
        } else if (name.includes('vitamin k')) {
          vitamins.K = parseFloat(value.toFixed(1));
        } else if (name.includes('folate')) {
          vitamins.folate = parseFloat(value.toFixed(1));
        }
      }
    }
    
    // Determine category
    const category = determineFoodCategory(foodName);
    
    // Generate searchable keywords
    const keywords = generateSearchKeywords(foodName, category);
    
    // Standard serving sizes based on category
    const servingSizes = generateServingSizes(category);
    
    return {
      foodName: foodName,
      searchableKeywords: keywords,
      fdcId: fdcId,
      dataType: dataType,
      category: category.main,
      subcategory: category.sub,
      nutritionPer100g: {
        ...nutrients,
        vitamins: Object.keys(vitamins).length > 0 ? vitamins : undefined,
        minerals: Object.keys(minerals).length > 0 ? minerals : undefined
      },
      allergens: determineAllergens(foodName),
      servingSizes: servingSizes,
      source: 'USDA',
      version: 1,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    };
  } catch (error) {
    console.error(`❌ Error transforming food ${usdaFood.description}:`, error.message);
    return null;
  }
}

function determineFoodCategory(foodName) {
  const name = foodName.toLowerCase();
  
  if (name.includes('apple') || name.includes('banana') || name.includes('orange') || 
      name.includes('berry') || name.includes('grape') || name.includes('peach') ||
      name.includes('pear') || name.includes('cherry') || name.includes('pineapple') ||
      name.includes('mango') || name.includes('kiwi') || name.includes('avocado')) {
    return { main: 'fruits', sub: null };
  }
  
  if (name.includes('broccoli') || name.includes('spinach') || name.includes('carrot') ||
      name.includes('tomato') || name.includes('potato') || name.includes('onion') ||
      name.includes('pepper') || name.includes('lettuce') || name.includes('cucumber') ||
      name.includes('celery') || name.includes('cauliflower') || name.includes('cabbage') ||
      name.includes('mushroom') || name.includes('zucchini')) {
    return { main: 'vegetables', sub: name.includes('leafy') ? 'leafy_greens' : null };
  }
  
  if (name.includes('chicken') || name.includes('beef') || name.includes('pork') ||
      name.includes('turkey') || name.includes('lamb') || name.includes('meat')) {
    return { main: 'proteins', sub: 'meat' };
  }
  
  if (name.includes('fish') || name.includes('salmon') || name.includes('tuna') ||
      name.includes('shrimp') || name.includes('crab') || name.includes('cod') ||
      name.includes('tilapia') || name.includes('halibut')) {
    return { main: 'proteins', sub: 'seafood' };
  }
  
  if (name.includes('egg')) {
    return { main: 'proteins', sub: 'eggs' };
  }
  
  if (name.includes('almond') || name.includes('walnut') || name.includes('peanut') ||
      name.includes('cashew') || name.includes('pistachio') || name.includes('pecan') ||
      name.includes('nut') || name.includes('seed')) {
    return { main: 'proteins', sub: 'nuts' };
  }
  
  if (name.includes('rice') || name.includes('bread') || name.includes('pasta') ||
      name.includes('oat') || name.includes('quinoa') || name.includes('barley') ||
      name.includes('wheat') || name.includes('grain') || name.includes('cereal')) {
    return { main: 'grains', sub: null };
  }
  
  if (name.includes('milk') || name.includes('cheese') || name.includes('yogurt') ||
      name.includes('butter') || name.includes('cream') || name.includes('dairy')) {
    return { main: 'dairy', sub: null };
  }
  
  if (name.includes('bean') || name.includes('lentil') || name.includes('chickpea') ||
      name.includes('peas') || name.includes('soybean')) {
    return { main: 'proteins', sub: 'legumes' };
  }
  
  return { main: 'other', sub: null };
}

function generateSearchKeywords(foodName, category) {
  const keywords = [foodName.toLowerCase()];
  const words = foodName.toLowerCase().split(/[\s,]+/);
  
  // Add individual words
  keywords.push(...words.filter(word => word.length > 2));
  
  // Add category-based keywords
  keywords.push(category.main);
  if (category.sub) {
    keywords.push(category.sub);
  }
  
  // Add common variations
  if (foodName.includes('raw')) {
    keywords.push('fresh', 'uncooked');
  }
  if (foodName.includes('cooked')) {
    keywords.push('prepared');
  }
  
  return [...new Set(keywords)]; // Remove duplicates
}

function generateServingSizes(category) {
  const defaultSizes = { '100g': 100 };
  
  switch (category.main) {
    case 'fruits':
      return { '1 medium': 150, '1 cup': 150, '1 small': 100, ...defaultSizes };
    case 'vegetables':
      return { '1 cup': 100, '1 serving': 85, ...defaultSizes };
    case 'proteins':
      if (category.sub === 'meat' || category.sub === 'seafood') {
        return { '3 oz': 85, '1 serving': 100, '1 fillet': 150, ...defaultSizes };
      } else if (category.sub === 'eggs') {
        return { '1 large': 50, '1 medium': 44, ...defaultSizes };
      } else if (category.sub === 'nuts') {
        return { '1 oz': 28, '1 handful': 30, ...defaultSizes };
      }
      return { '1 serving': 100, ...defaultSizes };
    case 'grains':
      return { '1 cup': 150, '0.5 cup': 75, '1 slice': 30, ...defaultSizes };
    case 'dairy':
      return { '1 cup': 245, '1 oz': 28, '1 serving': 170, ...defaultSizes };
    default:
      return defaultSizes;
  }
}

function determineAllergens(foodName) {
  const allergens = [];
  const name = foodName.toLowerCase();
  
  if (name.includes('milk') || name.includes('cheese') || name.includes('yogurt') ||
      name.includes('butter') || name.includes('cream') || name.includes('dairy')) {
    allergens.push('dairy');
  }
  
  if (name.includes('egg')) {
    allergens.push('eggs');
  }
  
  if (name.includes('peanut')) {
    allergens.push('peanuts');
  }
  
  if (name.includes('almond') || name.includes('walnut') || name.includes('cashew') ||
      name.includes('pecan') || name.includes('hazelnut') || name.includes('pistachio')) {
    allergens.push('tree nuts');
  }
  
  if (name.includes('fish') || name.includes('salmon') || name.includes('tuna') ||
      name.includes('cod') || name.includes('tilapia')) {
    allergens.push('fish');
  }
  
  if (name.includes('shrimp') || name.includes('crab') || name.includes('lobster')) {
    allergens.push('shellfish');
  }
  
  if (name.includes('wheat') || name.includes('bread') || name.includes('pasta')) {
    allergens.push('gluten');
  }
  
  if (name.includes('soy') || name.includes('soybean')) {
    allergens.push('soy');
  }
  
  return allergens;
}

async function populateExtendedUSDAFoods() {
  console.log('🍎 Starting Extended USDA Food Database Population...');
  console.log('🎯 Target: 200+ additional foods across comprehensive categories');
  
  try {
    // Check current database size
    const existingFoods = await db.collection('foods').get();
    console.log(`📊 Current foods in database: ${existingFoods.size}`);
    
    let allFoods = [];
    let totalSearched = 0;
    
    // Search across all categories
    console.log('\n🔍 Searching across comprehensive food categories...');
    
    for (const category of SEARCH_CATEGORIES) {
      process.stdout.write(`📋 ${category.term} (${category.count})... `);
      
      const searchResults = await searchFoods(category.term, category.count);
      const validFoods = searchResults.filter(food => 
        food.fdcId && 
        food.description && 
        food.foodNutrients && 
        food.foodNutrients.length > 0
      );
      
      allFoods.push(...validFoods.slice(0, category.count));
      totalSearched += validFoods.length;
      
      console.log(`✅ ${Math.min(validFoods.length, category.count)}`);
      
      // Add delay to respect rate limits
      await new Promise(resolve => setTimeout(resolve, 200));
    }
    
    console.log(`\n📊 Search Summary:`);
    console.log(`   Total foods found: ${totalSearched}`);
    console.log(`   Foods selected: ${allFoods.length}`);
    
    // Remove duplicates by FDC ID
    console.log('\n🔄 Removing duplicates and transforming data...');
    const seenFdcIds = new Set();
    const uniqueFoods = [];
    
    for (const food of allFoods) {
      if (!seenFdcIds.has(food.fdcId)) {
        seenFdcIds.add(food.fdcId);
        uniqueFoods.push(food);
      }
    }
    
    console.log(`   Unique foods after deduplication: ${uniqueFoods.length}`);
    
    // Transform USDA data
    const transformedFoods = [];
    for (const usdaFood of uniqueFoods) {
      const transformed = transformUSDAFood(usdaFood);
      if (transformed) {
        transformedFoods.push(transformed);
      }
    }
    
    console.log(`   Successfully transformed: ${transformedFoods.length} foods`);
    
    // Upload to Firebase in batches
    console.log('\n⬆️  Uploading to Firebase...');
    const batchSize = 500;
    let uploadedCount = 0;
    
    for (let i = 0; i < transformedFoods.length; i += batchSize) {
      const batch = db.batch();
      const batchFoods = transformedFoods.slice(i, i + batchSize);
      
      for (const food of batchFoods) {
        const docRef = db.collection('foods').doc();
        batch.set(docRef, food);
      }
      
      await batch.commit();
      uploadedCount += batchFoods.length;
      console.log(`   ✅ Uploaded ${uploadedCount}/${transformedFoods.length} foods`);
    }
    
    // Final statistics
    const finalCount = await db.collection('foods').get();
    
    console.log('\n🎉 Extended USDA food database population completed!');
    console.log(`📊 Final Statistics:`);
    console.log(`   Foods added this run: ${uploadedCount}`);
    console.log(`   Total foods in database: ${finalCount.size}`);
    console.log(`   Database growth: +${finalCount.size - existingFoods.size} foods`);
    
    // Show category breakdown of new foods
    const categories = {};
    transformedFoods.forEach(food => {
      categories[food.category] = (categories[food.category] || 0) + 1;
    });
    
    console.log('\n🏷️  New foods by category:');
    Object.entries(categories)
      .sort(([,a], [,b]) => b - a)
      .forEach(([category, count]) => {
        console.log(`   ${category}: ${count} foods`);
      });
    
  } catch (error) {
    console.error('❌ Error populating extended USDA foods:', error);
    process.exit(1);
  }
  
  process.exit(0);
}

populateExtendedUSDAFoods(); 