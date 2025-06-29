class FoodCorrection {
  final String id;
  final String originalFoodName;
  final String correctedFoodName;
  final double originalWeight;
  final double correctedWeight;
  final String correctionType;
  final DateTime timestamp;
  final String userId;
  final Map<String, dynamic>? metadata;

  const FoodCorrection({
    required this.id,
    required this.originalFoodName,
    required this.correctedFoodName,
    required this.originalWeight,
    required this.correctedWeight,
    required this.correctionType,
    required this.timestamp,
    required this.userId,
    this.metadata,
  });

  factory FoodCorrection.fromFirestore(Map<String, dynamic> data, String id) {
    return FoodCorrection(
      id: id,
      originalFoodName: data['originalFoodName'] ?? '',
      correctedFoodName: data['correctedFoodName'] ?? '',
      originalWeight: data['originalWeight']?.toDouble() ?? 0.0,
      correctedWeight: data['correctedWeight']?.toDouble() ?? 0.0,
      correctionType: data['correctionType'] ?? 'unknown',
      timestamp: data['timestamp']?.toDate() ?? DateTime.now(),
      userId: data['userId'] ?? '',
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'originalFoodName': originalFoodName,
      'correctedFoodName': correctedFoodName,
      'originalWeight': originalWeight,
      'correctedWeight': correctedWeight,
      'correctionType': correctionType,
      'timestamp': timestamp,
      'userId': userId,
      'metadata': metadata,
    };
  }

  bool get isNameCorrection => originalFoodName != correctedFoodName;
  bool get isWeightCorrection => originalWeight != correctedWeight;
  bool get isBothCorrection => isNameCorrection && isWeightCorrection;

  double get weightDifference => correctedWeight - originalWeight;
  double get weightDifferencePercent => 
      originalWeight > 0 ? (weightDifference / originalWeight) * 100 : 0;

  @override
  String toString() {
    return 'FoodCorrection(id: $id, original: $originalFoodName (${originalWeight}g), '
           'corrected: $correctedFoodName (${correctedWeight}g), type: $correctionType)';
  }
} 