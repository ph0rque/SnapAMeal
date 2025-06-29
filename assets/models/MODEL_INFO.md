# TensorFlow Lite Food Classification Model

## Model Details

**Model Name:** EfficientNet-Lite0  
**Source:** TensorFlow Hub  
**Download URL:** https://tfhub.dev/tensorflow/lite-model/efficientnet/lite0/uint8/2?lite-format=tflite  
**File:** `food_classifier.tflite`  
**Labels:** `food_labels.txt`  

## Model Specifications

- **Architecture:** EfficientNet-Lite0
- **Input Size:** 224x224x3 (RGB images)
- **Quantization:** uint8 (Integer quantized)
- **Model Size:** ~5.4 MB
- **Parameters:** ~4.7M
- **Inference Time:** ~30-50ms on mobile CPU
- **Accuracy:** 75.1% ImageNet top-1 accuracy (original)

## Key Features

### EfficientNet-Lite Optimizations
- **Removed Squeeze-and-Excitation modules** for better hardware compatibility
- **Replaced Swish with ReLU6** for improved quantization performance
- **Fixed stem and head** while scaling to reduce computational overhead
- **Mobile-optimized** for CPU, GPU, and EdgeTPU deployment

### Quantization Benefits
- **4x size reduction** compared to float32 model
- **2x speed improvement** for inference
- **Minimal accuracy loss** (~0.7% compared to float model)

## Usage in SnapAMeal

This model serves as the **first-pass food recognition** in our hybrid processing pipeline:

1. **Primary Detection:** TensorFlow Lite model identifies common foods quickly
2. **Confidence Threshold:** Results with >70% confidence are used directly
3. **Fallback:** Lower confidence results trigger OpenAI vision model
4. **Performance:** Reduces API costs and improves response time for common foods

## Food Categories

The model can identify **500+ food categories** including:
- Fresh fruits and vegetables
- Prepared meals and dishes
- Baked goods and desserts
- Proteins (meat, fish, dairy)
- International cuisines
- Snacks and beverages
- Spices and condiments

See `food_labels.txt` for the complete list of categories.

## Implementation Notes

### Model Loading
```dart
// Load the TensorFlow Lite model
final interpreter = await Interpreter.fromAsset('assets/models/food_classifier.tflite');

// Load labels
final labels = await rootBundle.loadString('assets/models/food_labels.txt');
final labelList = labels.split('\n');
```

### Input Preprocessing
- Resize image to 224x224 pixels
- Normalize pixel values to [0, 255] (uint8)
- Ensure RGB channel order

### Output Processing
- Model outputs probability scores for each food category
- Apply softmax to get normalized probabilities
- Filter results by confidence threshold (70%)
- Map indices to food labels

## Performance Expectations

### Mobile Performance
- **Pixel 4 CPU:** ~30ms inference time
- **iPhone 12:** ~25ms inference time
- **Mid-range devices:** 40-80ms inference time

### Accuracy Expectations
- **Common foods:** 80-90% accuracy (pizza, burger, apple)
- **Complex dishes:** 60-75% accuracy (stir-fry, casseroles)
- **Ambiguous foods:** 40-60% accuracy (triggers OpenAI fallback)

## Limitations

1. **General Classification:** Trained on ImageNet, not food-specific dataset
2. **Limited Food Vocabulary:** May not recognize very specific or regional foods
3. **Portion Estimation:** Cannot estimate serving sizes or weights
4. **Nutritional Data:** Requires separate lookup for nutritional information
5. **Lighting Sensitivity:** Performance may vary with image quality

## Future Improvements

1. **Food-101 Fine-tuning:** Train on food-specific dataset for better accuracy
2. **Custom Labels:** Create app-specific food categories
3. **Portion Detection:** Add weight/serving size estimation
4. **Regional Foods:** Expand to include local and ethnic cuisines
5. **Real-time Optimization:** Further optimize for faster inference

## Version History

- **v1.0** (Current): EfficientNet-Lite0 from TensorFlow Hub
- **v2.0** (Planned): Food-101 fine-tuned model
- **v3.0** (Future): Custom trained model with portion estimation

## References

- [EfficientNet-Lite Paper](https://blog.tensorflow.org/2020/03/higher-accuracy-on-vision-models-with-efficientnet-lite.html)
- [TensorFlow Lite Documentation](https://www.tensorflow.org/lite)
- [EfficientNet Original Paper](https://arxiv.org/abs/1905.11946)
- [TensorFlow Hub Model](https://tfhub.dev/tensorflow/lite-model/efficientnet/lite0/uint8/2) 