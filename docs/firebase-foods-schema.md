# Firebase Foods Collection Schema

## Overview

The `foods` collection in Firestore stores comprehensive nutritional data for foods, replacing the hardcoded database with a scalable, searchable solution. This schema is designed to be compatible with USDA FoodData Central API structure while optimized for mobile app queries.

## Collection: `foods`

### Document Structure

```typescript
interface FoodDocument {
  // Basic Information
  foodName: string;                    // Primary food name (e.g., "Apple, raw")
  searchableKeywords: string[];        // Array of searchable terms
  fdcId?: number;                      // USDA FoodData Central ID (if applicable)
  dataType: string;                    // Data source type
  
  // Categorization
  category: string;                    // Primary food category
  subcategory?: string;                // Optional subcategory
  
  // Nutritional Information (per 100g)
  nutritionPer100g: {
    // Macronutrients
    calories: number;                  // Energy (kcal)
    protein: number;                   // Protein (g)
    fat: number;                       // Total fat (g)
    carbs: number;                     // Total carbohydrates (g)
    fiber: number;                     // Dietary fiber (g)
    sugar: number;                     // Total sugars (g)
    
    // Micronutrients - Vitamins (mg/mcg as appropriate)
    vitamins: {
      A?: number;                      // Vitamin A, RAE (mcg)
      C?: number;                      // Vitamin C (mg)
      D?: number;                      // Vitamin D (mcg)
      E?: number;                      // Vitamin E (mg)
      K?: number;                      // Vitamin K (mcg)
      B1?: number;                     // Thiamin (mg)
      B2?: number;                     // Riboflavin (mg)
      B3?: number;                     // Niacin (mg)
      B6?: number;                     // Pyridoxine (mg)
      B12?: number;                    // Cobalamin (mcg)
      folate?: number;                 // Folate (mcg)
    };
    
    // Micronutrients - Minerals (mg/mcg as appropriate)
    minerals: {
      calcium?: number;                // Calcium (mg)
      iron?: number;                   // Iron (mg)
      magnesium?: number;              // Magnesium (mg)
      phosphorus?: number;             // Phosphorus (mg)
      potassium?: number;              // Potassium (mg)
      sodium?: number;                 // Sodium (mg)
      zinc?: number;                   // Zinc (mg)
      copper?: number;                 // Copper (mg)
      manganese?: number;              // Manganese (mg)
      selenium?: number;               // Selenium (mcg)
    };
    
    // Additional Nutrients
    cholesterol?: number;              // Cholesterol (mg)
    saturatedFat?: number;             // Saturated fat (g)
    monounsaturatedFat?: number;       // Monounsaturated fat (g)
    polyunsaturatedFat?: number;       // Polyunsaturated fat (g)
    transFat?: number;                 // Trans fat (g)
  };
  
  // Additional Information
  allergens?: string[];                // Common allergens
  servingSizes?: {                     // Common serving sizes
    [key: string]: number;             // e.g., "1 medium": 150, "1 cup": 125
  };
  
  // Metadata
  source: string;                      // Data source (e.g., "USDA", "manual", "community")
  createdAt: Timestamp;                // Document creation time
  updatedAt: Timestamp;                // Last update time
  version: number;                     // Schema version for migration
}
```

## Data Types and Categories

### Primary Categories
- `fruits` - Fresh and dried fruits
- `vegetables` - All vegetables and legumes  
- `grains` - Cereals, bread, pasta, rice
- `proteins` - Meat, fish, eggs, nuts, seeds
- `dairy` - Milk, cheese, yogurt
- `beverages` - All drinks except water
- `snacks` - Processed snack foods
- `desserts` - Sweets and confections
- `condiments` - Sauces, spices, seasonings
- `prepared` - Ready-made meals and dishes

### Data Source Types
- `foundation` - USDA Foundation Foods (highest quality)
- `sr_legacy` - USDA Standard Reference Legacy
- `survey` - USDA Survey (FNDDS) data
- `manual` - Manually entered data
- `community` - Community-contributed data

### Searchable Keywords Strategy
Keywords should include:
- Primary food name variations
- Common synonyms
- Brand names (if applicable)
- Preparation methods
- Regional names
- Ingredient components

## Query Patterns

### 1. Basic Food Search
```dart
// Search by food name
final query = FirebaseFirestore.instance
    .collection('foods')
    .where('searchableKeywords', arrayContains: searchTerm.toLowerCase())
    .orderBy('dataType')
    .limit(20);
```

### 2. Category-Based Queries
```dart
// Get foods by category
final query = FirebaseFirestore.instance
    .collection('foods')
    .where('category', isEqualTo: 'fruits')
    .orderBy('foodName')
    .limit(50);
```

### 3. Nutritional Filtering
```dart
// Find high-protein foods
final query = FirebaseFirestore.instance
    .collection('foods')
    .where('category', isEqualTo: 'proteins')
    .where('nutritionPer100g.protein', isGreaterThan: 15)
    .orderBy('nutritionPer100g.protein', descending: true);
```

## Validation Rules

### Required Fields
- `foodName` (non-empty string)
- `searchableKeywords` (non-empty array)
- `dataType` (valid enum value)
- `category` (valid enum value)
- `nutritionPer100g.calories` (non-negative number)
- `source` (non-empty string)
- `createdAt` (valid timestamp)
- `version` (positive integer)

### Data Constraints
- All nutritional values must be non-negative
- Calories should be reasonable (0-900 per 100g for most foods)
- Protein + fat + carbs should roughly equal total calories when converted
- Keywords should be lowercase for consistent searching
- Category must be from predefined list

## Performance Considerations

### Indexing Strategy
1. **Compound Index**: `searchableKeywords` (array-contains) + `dataType` (asc)
2. **Compound Index**: `foodName` (asc) + `category` (asc)  
3. **Compound Index**: `category` (asc) + `nutritionPer100g.calories` (asc)
4. **Single Field**: `fdcId` (for USDA lookups)

### Query Optimization
- Limit all queries to ≤50 results for performance
- Use pagination for large result sets
- Cache frequently accessed foods locally
- Implement debounced search to reduce query frequency

## Security Rules

```javascript
// Foods collection - read-only for authenticated users
match /foods/{foodId} {
  allow read: if request.auth != null;
  allow write: if false; // Only admin/server-side can write
  allow list: if request.auth != null && 
    (request.query.limit <= 50); // Limit query size
}
```

## Migration and Versioning

### Version History
- **v1.0**: Initial schema with basic nutritional data
- **v2.0** (planned): Enhanced micronutrient support
- **v3.0** (planned): Recipe and preparation method integration

### Migration Strategy
- Use `version` field to identify schema version
- Implement graceful degradation for older versions
- Batch update documents during schema changes
- Maintain backward compatibility where possible

## Sample Documents

### Example 1: Simple Fruit
```json
{
  "foodName": "Apple, raw",
  "searchableKeywords": ["apple", "raw apple", "fresh apple", "red apple", "green apple"],
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
      "K": 2.2
    },
    "minerals": {
      "potassium": 107,
      "calcium": 6,
      "magnesium": 5
    }
  },
  "allergens": [],
  "servingSizes": {
    "1 medium": 150,
    "1 large": 200,
    "1 cup sliced": 125
  },
  "source": "USDA",
  "createdAt": "2024-06-29T08:00:00Z",
  "updatedAt": "2024-06-29T08:00:00Z",
  "version": 1
}
```

### Example 2: Complex Prepared Food
```json
{
  "foodName": "Pizza, cheese, regular crust",
  "searchableKeywords": ["pizza", "cheese pizza", "regular crust", "plain pizza"],
  "fdcId": 174987,
  "dataType": "survey",
  "category": "prepared",
  "subcategory": "italian",
  "nutritionPer100g": {
    "calories": 266,
    "protein": 11.4,
    "fat": 10.4,
    "carbs": 33.0,
    "fiber": 2.3,
    "sugar": 3.6,
    "sodium": 598,
    "vitamins": {
      "A": 84,
      "C": 0.2,
      "B1": 0.29,
      "B2": 0.29,
      "B3": 4.2,
      "folate": 43
    },
    "minerals": {
      "calcium": 200,
      "iron": 2.5,
      "magnesium": 23,
      "phosphorus": 178,
      "potassium": 172,
      "zinc": 1.4
    },
    "cholesterol": 17,
    "saturatedFat": 4.9
  },
  "allergens": ["gluten", "dairy"],
  "servingSizes": {
    "1 slice": 107,
    "1 personal pizza": 170
  },
  "source": "USDA",
  "createdAt": "2024-06-29T08:00:00Z",
  "updatedAt": "2024-06-29T08:00:00Z",
  "version": 1
}
```

## Integration Points

### With Meal Recognition Service
- Query foods collection as fallback after USDA API
- Cache results locally for offline access
- Support fuzzy matching for food name variations

### With RAG Service
- Use nutritional data for recipe filtering
- Support queries like "high protein foods" or "low sodium options"
- Enable nutritional comparisons between foods

### With User Corrections
- Store user feedback in `feedback_corrections` collection
- Use corrections to improve food matching algorithms
- Aggregate corrections for database improvements

## Monitoring and Analytics

### Key Metrics
- Query performance and frequency
- Cache hit rates
- User correction frequency
- Data completeness by category

### Health Checks
- Validate nutritional data consistency
- Monitor for missing required fields
- Check index performance
- Track storage usage and costs

## Future Enhancements

1. **Recipe Integration**: Link to recipe database
2. **Seasonal Availability**: Track food seasonality
3. **Regional Variations**: Support location-specific foods
4. **Preparation Methods**: Different nutrition for cooking methods
5. **Portion Intelligence**: AI-powered serving size estimation
6. **User Preferences**: Personalized food recommendations
7. **Barcode Integration**: UPC code to food mapping
8. **Sustainability Data**: Environmental impact metrics 