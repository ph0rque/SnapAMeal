import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
      debugPrint("FCM Token: $fcmToken");
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
} 