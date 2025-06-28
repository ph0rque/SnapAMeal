import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    // Request permission
    await _firebaseMessaging.requestPermission();

    // On Apple platforms, we need to get the APNs token first.
    if (Platform.isIOS || Platform.isMacOS) {
      await _firebaseMessaging.getAPNSToken();
    }

    // Get the token
    final fcmToken = await _firebaseMessaging.getToken();

    if (fcmToken != null) {
      Logger.d("FCM Token: $fcmToken");
      _saveTokenToDatabase(fcmToken);
    }

    // Listen for token refreshes
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToDatabase);
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'fcmToken': token,
    });
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    // Placeholder implementation - in a real app you'd use flutter_local_notifications
    Logger.d("Cancelling all notifications");
  }

  /// Schedule a notification
  Future<void> scheduleNotification({
    String? id,
    required String title,
    required String body,
    DateTime? scheduledDate,
    DateTime? scheduledTime,
  }) async {
    // Placeholder implementation - in a real app you'd use flutter_local_notifications
    final time = scheduledDate ?? scheduledTime;
    Logger.d("Scheduling notification ($id): $title at $time");
  }

  // Health-focused notification methods

  /// Schedule fasting reminder notifications
  Future<void> scheduleFastingReminders({
    required Duration fastingDuration,
    required DateTime startTime,
  }) async {
    final endTime = startTime.add(fastingDuration);

    // Schedule milestone notifications
    final milestones = [0.25, 0.5, 0.75, 0.9]; // 25%, 50%, 75%, 90%

    for (final milestone in milestones) {
      final notificationTime = startTime.add(
        Duration(
          milliseconds: (fastingDuration.inMilliseconds * milestone).round(),
        ),
      );

      await scheduleNotification(
        id: 'fasting_milestone_${(milestone * 100).round()}',
        title: 'Fasting Progress 🔥',
        body:
            'You\'re ${(milestone * 100).round()}% through your fast! Keep going!',
        scheduledTime: notificationTime,
      );
    }

    // Schedule completion notification
    await scheduleNotification(
      id: 'fasting_complete',
      title: 'Fasting Complete! 🎉',
      body:
          'Congratulations! You\'ve completed your ${_formatDuration(fastingDuration)} fast.',
      scheduledTime: endTime,
    );
  }

  /// Schedule meal logging reminders
  Future<void> scheduleMealReminders() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Schedule reminders for typical meal times
    final mealTimes = [
      {'time': const Duration(hours: 8), 'meal': 'breakfast'},
      {'time': const Duration(hours: 12, minutes: 30), 'meal': 'lunch'},
      {'time': const Duration(hours: 18), 'meal': 'dinner'},
    ];

    for (final meal in mealTimes) {
      final mealTime = today.add(meal['time'] as Duration);

      if (mealTime.isAfter(now)) {
        await scheduleNotification(
          id: 'meal_reminder_${meal['meal']}',
          title: 'Meal Logging Reminder 🍽️',
          body:
              'Don\'t forget to log your ${meal['meal']}! Tap to use AI recognition.',
          scheduledTime: mealTime,
        );
      }
    }
  }

  /// Schedule water intake reminders
  Future<void> scheduleWaterReminders() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Schedule water reminders every 2 hours during waking hours (8 AM - 10 PM)
    for (int hour = 8; hour <= 22; hour += 2) {
      final reminderTime = today.add(Duration(hours: hour));

      if (reminderTime.isAfter(now)) {
        await scheduleNotification(
          id: 'water_reminder_$hour',
          title: 'Hydration Check 💧',
          body: 'Time for a water break! Stay hydrated for optimal health.',
          scheduledTime: reminderTime,
        );
      }
    }
  }

  /// Schedule AI advice notifications
  Future<void> scheduleAIAdviceNotifications() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    // Schedule daily AI insights
    final insightTime = tomorrow.add(const Duration(hours: 9)); // 9 AM next day

    await scheduleNotification(
      id: 'daily_ai_insights',
      title: 'Your Daily Health Insights 🧠',
      body: 'Your AI coach has new personalized recommendations for you!',
      scheduledTime: insightTime,
    );
  }

  /// Schedule community engagement reminders
  Future<void> scheduleCommunityReminders() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Schedule evening community check-in
    final communityTime = today.add(const Duration(hours: 19)); // 7 PM

    if (communityTime.isAfter(now)) {
      await scheduleNotification(
        id: 'community_reminder',
        title: 'Community Check-in 👥',
        body: 'Share your progress with your health groups and get motivated!',
        scheduledTime: communityTime,
      );
    }
  }

  /// Schedule streak maintenance reminders
  Future<void> scheduleStreakReminders() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Schedule evening streak reminder
    final streakTime = today.add(const Duration(hours: 21)); // 9 PM

    if (streakTime.isAfter(now)) {
      await scheduleNotification(
        id: 'streak_reminder',
        title: 'Don\'t Break Your Streak! 🔥',
        body: 'Keep your momentum going! Complete today\'s health goals.',
        scheduledTime: streakTime,
      );
    }
  }

  /// Schedule weekly health summary
  Future<void> scheduleWeeklyHealthSummary() async {
    final now = DateTime.now();
    final daysUntilSunday = (7 - now.weekday) % 7;
    final nextSunday = DateTime(now.year, now.month, now.day + daysUntilSunday);
    final summaryTime = nextSunday.add(
      const Duration(hours: 18),
    ); // 6 PM Sunday

    await scheduleNotification(
      id: 'weekly_health_summary',
      title: 'Weekly Health Summary 📊',
      body: 'See your week\'s progress and get insights for the week ahead!',
      scheduledTime: summaryTime,
    );
  }

  /// Cancel health-specific notifications
  Future<void> cancelHealthNotifications() async {
    final notificationIds = [
      'fasting_milestone_25',
      'fasting_milestone_50',
      'fasting_milestone_75',
      'fasting_milestone_90',
      'fasting_complete',
      'meal_reminder_breakfast',
      'meal_reminder_lunch',
      'meal_reminder_dinner',
      'daily_ai_insights',
      'community_reminder',
      'streak_reminder',
      'weekly_health_summary',
    ];

    for (final id in notificationIds) {
      // In a real implementation, cancel specific notification by ID
      Logger.d("Cancelling notification: $id");
    }

    // Cancel water reminders
    for (int hour = 8; hour <= 22; hour += 2) {
      Logger.d("Cancelling notification: water_reminder_$hour");
    }
  }

  /// Setup default health notification schedule
  Future<void> setupHealthNotificationSchedule() async {
    await scheduleMealReminders();
    await scheduleWaterReminders();
    await scheduleAIAdviceNotifications();
    await scheduleCommunityReminders();
    await scheduleStreakReminders();
    await scheduleWeeklyHealthSummary();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }
}
