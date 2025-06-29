const admin = require('firebase-admin');
require('dotenv').config({ path: '../.env' });

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'snapameal-cabc7'
});

const db = admin.firestore();

async function checkFoodCount() {
  console.log('🔍 Checking food database statistics...');
  
  try {
    // Get all foods
    const foodsSnapshot = await db.collection('foods').get();
    const totalCount = foodsSnapshot.size;
    
    console.log(`📊 Total foods in database: ${totalCount}`);
    
    if (totalCount > 0) {
      // Analyze by source
      const sources = {};
      const categories = {};
      
      foodsSnapshot.forEach(doc => {
        const data = doc.data();
        const source = data.source || 'Unknown';
        const category = data.category || 'Unknown';
        
        sources[source] = (sources[source] || 0) + 1;
        categories[category] = (categories[category] || 0) + 1;
      });
      
      console.log('\n📋 Breakdown by source:');
      Object.entries(sources).forEach(([source, count]) => {
        console.log(`   ${source}: ${count} foods`);
      });
      
      console.log('\n🏷️  Breakdown by category:');
      Object.entries(categories).forEach(([category, count]) => {
        console.log(`   ${category}: ${count} foods`);
      });
      
      // Show some sample foods
      console.log('\n🍎 Sample foods:');
      let sampleCount = 0;
      foodsSnapshot.forEach(doc => {
        if (sampleCount < 5) {
          const data = doc.data();
          const calories = data.nutritionPer100g?.calories || 'N/A';
          console.log(`   • ${data.foodName} (${calories} cal/100g) - ${data.source}`);
          sampleCount++;
        }
      });
    }
    
  } catch (error) {
    console.error('❌ Error checking food count:', error);
  }
  
  process.exit(0);
}

checkFoodCount(); 