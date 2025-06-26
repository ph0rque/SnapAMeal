import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snapameal/pages/health_dashboard_page.dart';
import 'package:snapameal/pages/health_onboarding_page.dart';
import 'package:snapameal/pages/login_or_register.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Show a loading spinner while waiting for connection
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // user is logged in
          if (snapshot.hasData) {
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('health_profiles')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (context, profileSnapshot) {
                if (profileSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                // Check if user has completed health onboarding
                if (profileSnapshot.hasData && profileSnapshot.data!.exists) {
                  // User has health profile, go to dashboard
                  return const HealthDashboardPage();
                } else {
                  // User needs to complete health onboarding
                  return const HealthOnboardingPage();
                }
              },
            );
          }

          // user is NOT logged in
          else {
            return const LoginOrRegister();
          }
        },
      ),
    );
  }
} 