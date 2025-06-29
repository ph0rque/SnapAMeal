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
  console.log('   Get your free API key at: https://fdc.nal.usda.gov/api-key-signup.html');
  process.exit(1);
}

// Popular food FDC IDs to fetch from USDA
const POPULAR_FOOD_IDS = [
  // Fruits
  171688, // Apple, raw
  173944, // Banana, raw
  171706, // Avocado, raw
  167762, // Orange, raw
  168153, // Strawberries, raw
  169094, // Blueberries, raw
  167746, // Grapes, raw
  
  // Vegetables
  170379, // Broccoli, raw
  168462, // Spinach, raw
  169967, // Carrots, raw
  170457, // Sweet potato, raw
  169228, // Tomatoes, red, ripe, raw
  168409, // Onions, raw
  170393, // Bell peppers, red, raw
  
  // Proteins
  171477, // Chicken breast, skinless, boneless, raw
  174608, // Beef, ground, 85% lean meat / 15% fat, raw
  175167, // Salmon, Atlantic, cooked
  175149, // Tuna, yellowfin, fresh, cooked
  171287, // Egg, whole, raw
  
  // Grains
  168880, // Brown rice, cooked
  170684, // Oats, rolled, raw
  168917, // Quinoa, cooked
  169716, // Bread, whole wheat
  
  // Dairy
  171265, // Cheddar cheese
  170895, // Greek yogurt, plain, nonfat
  171256, // Milk, whole, 3.25% milkfat
  
  // Nuts & Seeds
  170567, // Almonds, raw
  170187, // Walnuts, raw
  170155, // Peanuts, raw
  
  // Legumes
  172421, // Beans, black, cooked
  175204, // Chickpeas, cooked
  172420, // Lentils, cooked
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

async function fetchFoodsByIds(fdcIds) {
  console.log(`🔍 Fetching ${fdcIds.length} foods by FDC IDs...`);
  
  try {
    const response = await makeUSDARequest('/foods', {
      fdcIds: fdcIds.join(','),
      format: 'full'
    });
    
    return response.foods || [];
  } catch (error) {
    console.error('❌ Error fetching foods by IDs:', error.message);
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
      name.includes('berry') || name.includes('grape') || name.includes('avocado')) {
    return { main: 'fruits', sub: null };
  }
  
  if (name.includes('broccoli') || name.includes('spinach') || name.includes('carrot') ||
      name.includes('tomato') || name.includes('pepper') || name.includes('onion')) {
    return { main: 'vegetables', sub: name.includes('leafy') ? 'leafy_greens' : null };
  }
  
  if (name.includes('chicken') || name.includes('beef') || name.includes('pork') ||
      name.includes('turkey') || name.includes('meat')) {
    return { main: 'proteins', sub: 'meat' };
  }
  
  if (name.includes('fish') || name.includes('salmon') || name.includes('tuna') ||
      name.includes('shrimp') || name.includes('crab') || name.includes('cod')) {
    return { main: 'proteins', sub: 'seafood' };
  }
  
  if (name.includes('egg')) {
    return { main: 'proteins', sub: 'eggs' };
  }
  
  if (name.includes('almond') || name.includes('walnut') || name.includes('peanut') ||
      name.includes('cashew') || name.includes('nut')) {
    return { main: 'proteins', sub: 'nuts' };
  }
  
  if (name.includes('rice') || name.includes('bread') || name.includes('pasta') ||
      name.includes('oat') || name.includes('quinoa') || name.includes('grain')) {
    return { main: 'grains', sub: null };
  }
  
  if (name.includes('milk') || name.includes('cheese') || name.includes('yogurt') ||
      name.includes('dairy')) {
    return { main: 'dairy', sub: null };
  }
  
  if (name.includes('bean') || name.includes('lentil') || name.includes('chickpea') ||
      name.includes('soybean')) {
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
      name.includes('dairy')) {
    allergens.push('dairy');
  }
  
  if (name.includes('egg')) {
    allergens.push('eggs');
  }
  
  if (name.includes('peanut')) {
    allergens.push('peanuts');
  }
  
  if (name.includes('almond') || name.includes('walnut') || name.includes('cashew') ||
      name.includes('pecan') || name.includes('hazelnut')) {
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

async function populateUSDAFoods() {
  console.log('🍎 Starting USDA Food Database Population...');
  console.log(`📊 API Key configured: ${USDA_API_KEY ? 'Yes' : 'No'}`);
  
  try {
    // Check if foods collection already has extensive data
    const existingFoods = await db.collection('foods').get();
    console.log(`📊 Current foods in database: ${existingFoods.size}`);
    
    if (existingFoods.size > 50) {
      console.log(`⚠️  Foods collection already contains ${existingFoods.size} items.`);
      console.log('   This will add USDA foods to the existing collection.');
      console.log('   Continue? (Ctrl+C to abort)');
      
      // Wait 3 seconds for user to abort if needed
      await new Promise(resolve => setTimeout(resolve, 3000));
    }
    
    // Step 1: Fetch popular foods by FDC IDs
    console.log('📋 Step 1: Fetching popular foods by FDC IDs...');
    const popularFoods = await fetchFoodsByIds(POPULAR_FOOD_IDS);
    console.log(`   ✅ Fetched ${popularFoods.length} popular foods from USDA`);
    
    // Step 2: Transform USDA data
    console.log('🔄 Step 2: Transforming USDA data...');
    const transformedFoods = [];
    const seenFdcIds = new Set();
    
    for (const usdaFood of popularFoods) {
      if (seenFdcIds.has(usdaFood.fdcId)) continue;
      seenFdcIds.add(usdaFood.fdcId);
      
      const transformed = transformUSDAFood(usdaFood);
      if (transformed) {
        transformedFoods.push(transformed);
      }
    }
    
    console.log(`   ✅ Transformed ${transformedFoods.length} unique foods`);
    
    // Step 3: Upload to Firebase
    console.log('⬆️  Step 3: Uploading to Firebase...');
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
    
    console.log('🎉 USDA food database population completed!');
    console.log(`📊 Final stats: ${uploadedCount} foods uploaded to Firebase`);
    
    // Show some examples
    if (transformedFoods.length > 0) {
      console.log('\n📋 Sample foods added:');
      for (let i = 0; i < Math.min(5, transformedFoods.length); i++) {
        const food = transformedFoods[i];
        console.log(`   • ${food.foodName} (${food.nutritionPer100g.calories} cal/100g)`);
      }
    }
    
  } catch (error) {
    console.error('❌ Error populating USDA foods:', error);
    process.exit(1);
  }
  
  process.exit(0);
}

populateUSDAFoods(); 