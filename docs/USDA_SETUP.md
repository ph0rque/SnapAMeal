# USDA Food Database Integration Setup

## Overview
SnapAMeal can integrate with the USDA FoodData Central API to provide comprehensive, authoritative nutritional data for thousands of foods. This integration offers:

- **Official USDA nutritional data** for 300,000+ foods
- **Detailed nutrient profiles** including vitamins, minerals, and fatty acids
- **Multiple food types** - Foundation Foods, SR Legacy, Survey Foods
- **Comprehensive search capabilities** by food name or nutrient content
- **Free API access** with reasonable rate limits

## Getting Started

### 1. Get Your Free USDA API Key

1. Visit the [USDA FoodData Central API signup page](https://fdc.nal.usda.gov/api-key-signup.html)
2. Fill out the simple registration form:
   - Name
   - Email address
   - Organization (can be "Personal" or "Individual")
   - Intended use (e.g., "Mobile app for meal tracking")
3. You'll receive your API key immediately via email

### 2. Add API Key to Environment

Add your USDA API key to your `.env` file:

```bash
# USDA FoodData Central API
USDA_API_KEY=your_actual_api_key_here
```

### 3. Run the Population Script

Once your API key is configured, you can populate your Firebase database with USDA food data:

```bash
# From the functions directory (where firebase-admin is installed)
cd functions
node ../scripts/populate_usda_foods.js
```

## What Gets Populated

The script fetches and transforms data for **30+ popular foods** including:

### 🍎 Fruits
- Apple, Banana, Avocado, Orange, Strawberries, Blueberries, Grapes

### 🥬 Vegetables  
- Broccoli, Spinach, Carrots, Sweet potato, Tomatoes, Onions, Bell peppers

### 🍗 Proteins
- Chicken breast, Ground beef, Salmon, Tuna, Eggs

### 🌾 Grains
- Brown rice, Oats, Quinoa, Whole wheat bread

### 🥛 Dairy
- Cheddar cheese, Greek yogurt, Milk

### 🥜 Nuts & Legumes
- Almonds, Walnuts, Peanuts, Black beans, Chickpeas, Lentils

## Data Structure

Each USDA food item includes:

```json
{
  "foodName": "Apple, raw",
  "searchableKeywords": ["apple", "raw", "fresh", "fruit"],
  "fdcId": 171688,
  "dataType": "foundation",
  "category": "fruits",
  "nutritionPer100g": {
    "calories": 52,
    "protein": 0.26,
    "fat": 0.17,
    "carbs": 13.81,
    "fiber": 2.4,
    "sugar": 10.39,
    "vitamins": {
      "C": 4.6,
      "K": 2.2,
      "A": 3
    },
    "minerals": {
      "potassium": 107,
      "calcium": 6,
      "iron": 0.12
    }
  },
  "allergens": [],
  "servingSizes": {
    "1 medium": 150,
    "1 cup": 150,
    "1 small": 100,
    "100g": 100
  },
  "source": "USDA",
  "version": 1
}
```

## API Rate Limits

The USDA API has generous rate limits:
- **3,600 requests per hour** (1 per second)
- **No daily limit** for reasonable use
- **Batch requests supported** for efficiency

## Advanced Usage

### Custom Food Lists
You can modify `POPULAR_FOOD_IDS` in the script to fetch specific foods by their FDC ID:

```javascript
const CUSTOM_FOOD_IDS = [
  171688, // Apple, raw
  173944, // Banana, raw
  // Add more FDC IDs as needed
];
```

### Search Integration
For dynamic food search, you can use the USDA search endpoint:

```javascript
const searchResults = await makeUSDARequest('/foods/search', {
  query: 'chicken breast',
  dataType: 'Foundation,SR Legacy',
  pageSize: 50
});
```

## Benefits Over Static Data

| Feature | Static Data | USDA Integration |
|---------|-------------|------------------|
| **Food Coverage** | ~13 foods | 300,000+ foods |
| **Data Authority** | Sample data | Official USDA |
| **Nutrient Detail** | Basic macros | 150+ nutrients |
| **Updates** | Manual | Automatic |
| **Search Quality** | Limited | Comprehensive |
| **Serving Sizes** | Generic | Food-specific |

## Troubleshooting

### API Key Issues
```bash
❌ USDA_API_KEY not found in environment variables
```
**Solution**: Add your API key to `.env` file

### Rate Limiting
```bash
❌ Error fetching foods: 429 Too Many Requests
```
**Solution**: The script includes delays. For custom usage, add `setTimeout()` between requests.

### No Foods Returned
```bash
📊 Total foods fetched: 0
```
**Solution**: Check your API key validity and internet connection.

## Next Steps

After populating USDA data:

1. **Test meal recognition** - The app will now have access to comprehensive food data
2. **Monitor usage** - Check Firebase storage and API usage
3. **Expand coverage** - Add more food categories as needed
4. **Update regularly** - Run the script periodically for new USDA data

## Resources

- [USDA FoodData Central](https://fdc.nal.usda.gov/)
- [API Documentation](https://fdc.nal.usda.gov/api-guide.html)
- [Food Data Types](https://fdc.nal.usda.gov/data-documentation.html)
- [Nutrient Lists](https://fdc.nal.usda.gov/portal-data/external/dataDictionary) 