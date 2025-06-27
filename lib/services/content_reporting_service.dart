/// Content Reporting Service for user feedback on AI-generated content
/// Allows users to report inappropriate or harmful AI advice
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import 'content_validation_service.dart';

/// Service for handling user reports of inappropriate AI content
class ContentReportingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Report inappropriate AI-generated content
  static Future<bool> reportContent({
    required String userId,
    required String content,
    required String contentType, // 'insight', 'recipe', 'nutrition', 'story_summary'
    required String reason,
    String? additionalDetails,
  }) async {
    try {
      // Generate content report
      final report = ContentValidationService.generateContentReport(
        content: content,
        userId: userId,
        contentType: contentType,
        reason: reason,
      );

      // Add additional details if provided
      if (additionalDetails != null && additionalDetails.isNotEmpty) {
        report['additionalDetails'] = additionalDetails;
      }

      // Add report status
      report['status'] = 'pending_review';
      report['reviewedAt'] = null;
      report['reviewedBy'] = null;
      report['action'] = null;

      // Store in Firestore
      await _firestore.collection('content_reports').add(report);

      Logger.d('Content report submitted successfully for user: $userId');
      return true;
    } catch (e) {
      Logger.d('Error submitting content report: $e');
      return false;
    }
  }

  /// Get user's previous reports
  static Future<List<Map<String, dynamic>>> getUserReports(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('content_reports')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      Logger.d('Error fetching user reports: $e');
      return [];
    }
  }

  /// Check if user has already reported this content
  static Future<bool> hasUserReportedContent({
    required String userId,
    required String content,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('content_reports')
          .where('userId', isEqualTo: userId)
          .where('content', isEqualTo: content)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      Logger.d('Error checking existing reports: $e');
      return false;
    }
  }

  /// Get predefined report reasons
  static List<String> getReportReasons() {
    return [
      'Contains medical advice',
      'Potentially harmful information',
      'Inappropriate for my goals',
      'Factually incorrect',
      'Offensive or inappropriate',
      'Spam or repetitive',
      'Other',
    ];
  }

  /// Submit feedback about AI content quality (not necessarily a report)
  static Future<bool> submitContentFeedback({
    required String userId,
    required String content,
    required String contentType,
    required bool isHelpful,
    String? feedback,
  }) async {
    try {
      final feedbackData = {
        'userId': userId,
        'content': content,
        'contentType': contentType,
        'isHelpful': isHelpful,
        'feedback': feedback,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _firestore.collection('content_feedback').add(feedbackData);

      Logger.d('Content feedback submitted successfully');
      return true;
    } catch (e) {
      Logger.d('Error submitting content feedback: $e');
      return false;
    }
  }

  /// Get content feedback statistics for monitoring
  static Future<Map<String, dynamic>> getContentFeedbackStats() async {
    try {
      final snapshot = await _firestore
          .collection('content_feedback')
          .get();

      final total = snapshot.docs.length;
      final helpful = snapshot.docs.where((doc) => doc.data()['isHelpful'] == true).length;
      final notHelpful = total - helpful;

      return {
        'total': total,
        'helpful': helpful,
        'notHelpful': notHelpful,
        'helpfulPercentage': total > 0 ? (helpful / total * 100).round() : 0,
      };
    } catch (e) {
      Logger.d('Error fetching feedback stats: $e');
      return {
        'total': 0,
        'helpful': 0,
        'notHelpful': 0,
        'helpfulPercentage': 0,
      };
    }
  }
} 