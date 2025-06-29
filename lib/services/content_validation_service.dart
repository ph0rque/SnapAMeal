/// Content Validation Service for AI-generated content safety
/// Filters potentially harmful advice and validates content before display
library;

import 'package:snapameal/utils/logger.dart';

/// Service for validating AI-generated content for safety
class ContentValidationService {
  static final ContentValidationService _instance = ContentValidationService._internal();
  factory ContentValidationService() => _instance;
  ContentValidationService._internal();

  // Keywords that indicate potential medical advice that should be blocked
  static const List<String> _medicalKeywords = [
    'diagnose', 'diagnosis', 'disease', 'medication', 'prescription',
    'treatment', 'cure', 'symptoms', 'medical condition', 'disorder',
    'therapy', 'drug', 'medicine', 'illness', 'infection', 'cancer',
    'diabetes', 'hypertension', 'depression', 'anxiety', 'bipolar',
    'schizophrenia', 'adhd', 'autism', 'allergy', 'allergic reaction',
    'emergency', 'urgent care', 'hospital', 'doctor', 'physician',
    'specialist', 'psychiatrist', 'psychologist', 'therapist'
  ];

  // Keywords that indicate harmful advice
  static const _harmfulKeywords = [
    'extreme diet', 'starvation', 'purge', 'laxative', 'diet pill',
    'crash diet', 'fast for days', 'stop eating', 'skip meals',
    'dangerous', 'risky', 'unsafe', 'harmful'
  ];



  /// Validate content for safety before displaying to users
  static ContentValidationResult validateContent(String content) {
    if (content.trim().isEmpty) {
      return ContentValidationResult(
        isValid: false,
        reason: 'Empty content',
        filteredContent: '',
      );
    }

    final lowerContent = content.toLowerCase();
    final issues = <String>[];

    // Check for medical advice keywords
    for (final keyword in _medicalKeywords) {
      if (lowerContent.contains(keyword)) {
        issues.add('Contains medical advice keyword: $keyword');
      }
    }

    // Check for harmful advice keywords
    for (final keyword in _harmfulKeywords) {
      if (lowerContent.contains(keyword)) {
        issues.add('Contains potentially harmful advice: $keyword');
      }
    }

    // Check if content lacks safety disclaimer
    final hasDisclaimer = lowerContent.contains('not a substitute for professional medical advice') ||
        lowerContent.contains('consult with a healthcare professional') ||
        lowerContent.contains('general wellness purposes only');

    if (!hasDisclaimer) {
      issues.add('Missing safety disclaimer');
    }

    // Determine if content is valid
    final isValid = issues.isEmpty || _isAcceptableWithWarnings(issues);
    
    return ContentValidationResult(
      isValid: isValid,
      reason: issues.isEmpty ? 'Content passed validation' : issues.join('; '),
      filteredContent: isValid ? content : _generateSafeAlternative(),
      warnings: issues,
    );
  }

  /// Check if content is acceptable despite minor warnings
  static bool _isAcceptableWithWarnings(List<String> issues) {
    // Allow content that only has disclaimer issues (we can add disclaimer)
    if (issues.length == 1 && issues.first.contains('Missing safety disclaimer')) {
      return true;
    }
    
    // Allow content with medical keywords if the only other issue is missing disclaimer
    if (issues.length == 2) {
      final hasDisclaimerIssue = issues.any((issue) => issue.contains('Missing safety disclaimer'));
      final hasMedicalKeywordOnly = issues.any((issue) => issue.contains('Contains medical advice keyword'));
      final hasNoHarmfulAdvice = !issues.any((issue) => issue.contains('potentially harmful advice'));
      
      return hasDisclaimerIssue && hasMedicalKeywordOnly && hasNoHarmfulAdvice;
    }
    
    return false;
  }

  /// Generate safe alternative content when original fails validation
  static String _generateSafeAlternative() {
    return '''
I'd be happy to help with general wellness information! However, I want to make sure I provide safe, appropriate guidance.

For specific health concerns or medical questions, I recommend consulting with a healthcare professional who can provide personalized advice based on your individual situation.

I'm here to help with general nutrition education, lifestyle tips, and wellness information that supports your overall health journey.

*This information is for general wellness purposes only and is not a substitute for professional medical advice, diagnosis, or treatment.*
''';
  }

  /// Validate and sanitize content, adding disclaimers if needed
  static String validateAndSanitize(String content) {
    final result = validateContent(content);
    
    if (!result.isValid) {
      Logger.d('Content validation failed: ${result.reason}');
      return result.filteredContent;
    }

    // Add disclaimer if missing
    if (result.warnings.any((w) => w.contains('Missing safety disclaimer'))) {
      const disclaimer = "\n\n*This information is for general wellness purposes only and is not a substitute for professional medical advice, diagnosis, or treatment. Always consult with a healthcare professional for medical concerns.*";
      return content + disclaimer;
    }

    return content;
  }

  /// Check if content requires human review
  static bool requiresHumanReview(String content) {
    final result = validateContent(content);
    return !result.isValid && result.warnings.any((w) => 
      w.contains('medical advice') || w.contains('harmful advice'));
  }

  /// Generate content report for user reporting
  static Map<String, dynamic> generateContentReport({
    required String content,
    required String userId,
    required String contentType,
    required String reason,
  }) {
    return {
      'content': content,
      'userId': userId,
      'contentType': contentType, // 'insight', 'recipe', 'nutrition', etc.
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
      'validationResult': validateContent(content).toJson(),
    };
  }
}

/// Result of content validation
class ContentValidationResult {
  final bool isValid;
  final String reason;
  final String filteredContent;
  final List<String> warnings;

  ContentValidationResult({
    required this.isValid,
    required this.reason,
    required this.filteredContent,
    this.warnings = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'reason': reason,
      'filteredContent': filteredContent,
      'warnings': warnings,
    };
  }
} 