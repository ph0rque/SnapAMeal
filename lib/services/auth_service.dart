import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snapameal/config/demo_personas.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

class AuthService {
  // auth & firestore instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // demo account cache for instant authentication (stores user IDs)
  static final Map<String, String> _demoAccountCache = {};

  // private constructor
  AuthService._();

  // singleton instance
  static final AuthService _instance = AuthService._();

  // factory constructor to return the singleton instance
  factory AuthService() {
    return _instance;
  }

  // get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // sign in with email and password (preserved existing functionality)
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      // Validate inputs
      if (email.trim().isEmpty || password.trim().isEmpty) {
        throw Exception('Email and password are required');
      }

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Clear demo cache when regular user signs in
      _demoAccountCache.clear();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Provide user-friendly error messages while preserving existing behavior
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found with this email address');
        case 'wrong-password':
          throw Exception('Incorrect password');
        case 'invalid-email':
          throw Exception('Invalid email address format');
        case 'user-disabled':
          throw Exception('This account has been disabled');
        case 'too-many-requests':
          throw Exception('Too many failed attempts. Please try again later');
        default:
          throw Exception(e.message ?? e.code);
      }
    }
  }

  // sign in with demo account (optimized for instant authentication)
  Future<UserCredential> signInWithDemoAccount(String personaId) async {
    try {
      // Validate input
      if (personaId.trim().isEmpty) {
        throw Exception('Demo persona ID cannot be empty');
      }

      final persona = DemoPersonas.getById(personaId);
      if (persona == null) {
        throw Exception('Demo persona not found: $personaId');
      }

      // Persist the last-used demo persona for faster UI defaults
      await _cacheLastDemoPersona(personaId);

      // Try instant authentication with optimized flow
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: persona.email,
          password: persona.password,
        );

        // Cache successful login for future reference
        if (userCredential.user != null) {
          _demoAccountCache[personaId] = userCredential.user!.uid;
        }

        return userCredential;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          // Create demo account if it doesn't exist
          final newUserCredential = await _createDemoAccount(persona);
          if (newUserCredential.user != null) {
            _demoAccountCache[personaId] = newUserCredential.user!.uid;
          }
          return newUserCredential;
        } else if (e.code == 'wrong-password') {
          // This shouldn't happen with demo accounts, but handle gracefully
          throw Exception(
            'Demo account authentication failed. Please try again.',
          );
        } else {
          throw Exception('Authentication error: ${e.message ?? e.code}');
        }
      }
    } catch (e) {
      throw Exception('Demo login failed: $e');
    }
  }

  // Cache last-used demo persona locally
  Future<void> _cacheLastDemoPersona(String personaId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_demo_persona', personaId);
    } catch (_) {
      /* ignore cache errors */
    }
  }

  /// Retrieve the last-used demo persona ID (or null).
  Future<String?> getLastDemoPersona() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('last_demo_persona');
    } catch (_) {
      return null;
    }
  }

  // create demo account with comprehensive validation
  Future<UserCredential> _createDemoAccount(DemoPersona persona) async {
    try {
      // Validate persona data
      if (!_validateDemoPersona(persona)) {
        throw Exception('Invalid demo persona data');
      }

      // create user (Firebase handles duplicate email protection)
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: persona.email,
            password: persona.password,
          );

      // save user info in a separate doc with demo flag
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': persona.email,
        'username': persona.username,
        'displayName': persona.displayName,
        'isDemo': true,
        'demoPersonaId': persona.id,
        'age': persona.age,
        'occupation': persona.occupation,
        'healthProfile': persona.healthProfile,
        'lastReplayTimestamp': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      Logger.d(
        '✅ Demo account created successfully: ${persona.displayName} (${persona.email})',
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      Logger.d(
        '❌ Firebase error creating demo account: ${e.code} - ${e.message}',
      );
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception(
            'Demo account already exists. Please contact support.',
          );
        case 'weak-password':
          throw Exception(
            'Demo account configuration error. Please try again.',
          );
        case 'invalid-email':
          throw Exception(
            'Demo account email configuration error. Please contact support.',
          );
        default:
          throw Exception(
            'Failed to create demo account: ${e.message ?? e.code}',
          );
      }
    } catch (e) {
      Logger.d('❌ General error creating demo account: $e');
      throw Exception('Demo account creation failed: $e');
    }
  }

  // validate demo persona data
  bool _validateDemoPersona(DemoPersona persona) {
    try {
      // Check required fields
      if (persona.id.isEmpty ||
          persona.email.isEmpty ||
          persona.password.isEmpty ||
          persona.username.isEmpty ||
          persona.displayName.isEmpty) {
        Logger.d('❌ Demo persona validation failed: Missing required fields');
        return false;
      }

      // Validate email format
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(persona.email)) {
        Logger.d('❌ Demo persona validation failed: Invalid email format');
        return false;
      }

      // Validate password strength
      if (persona.password.length < 8) {
        Logger.d('❌ Demo persona validation failed: Password too short');
        return false;
      }

      // Validate health profile structure
      if (persona.healthProfile.isEmpty) {
        Logger.d('❌ Demo persona validation failed: Missing health profile');
        return false;
      }

      return true;
    } catch (e) {
      Logger.d('❌ Demo persona validation error: $e');
      return false;
    }
  }

  // sign up with email and password (preserved existing functionality)
  Future<UserCredential> signUpWithEmailPassword(
    String email,
    String password,
    String username,
  ) async {
    try {
      // Validate inputs
      if (email.trim().isEmpty ||
          password.trim().isEmpty ||
          username.trim().isEmpty) {
        throw Exception('Email, password, and username are required');
      }

      // create user
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      // save user info in a separate doc (preserved existing structure)
      await _firestore.collection("users").doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email.trim(),
        'username': username.trim(),
        'isDemo': false, // Explicitly mark as non-demo
        'lastReplayTimestamp': null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Clear demo cache when new user registers
      _demoAccountCache.clear();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Provide user-friendly error messages while preserving existing behavior
      switch (e.code) {
        case 'weak-password':
          throw Exception(
            'Password is too weak. Please choose a stronger password',
          );
        case 'email-already-in-use':
          throw Exception('An account already exists with this email address');
        case 'invalid-email':
          throw Exception('Invalid email address format');
        default:
          throw Exception(e.message ?? e.code);
      }
    }
  }

  // get user data
  Future<DocumentSnapshot> getUserData(String uid) {
    return _firestore.collection("users").doc(uid).get();
  }

  // check if current user is a demo account
  Future<bool> isCurrentUserDemo() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await getUserData(user.uid);
    final data = doc.data() as Map<String, dynamic>?;
    return data?['isDemo'] ?? false;
  }

  // get demo persona id for current user
  Future<String?> getCurrentDemoPersonaId() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await getUserData(user.uid);
    final data = doc.data() as Map<String, dynamic>?;
    return data?['demoPersonaId'];
  }

  Future<bool> canUserReplay() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final doc = await getUserData(user.uid);
    final data = doc.data() as Map<String, dynamic>?;
    final lastReplay = data?['lastReplayTimestamp'] as Timestamp?;

    if (lastReplay == null) {
      return true; // Never replayed before
    }

    final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
    return lastReplay.toDate().isBefore(oneDayAgo);
  }

  Future<void> useReplayCredit() async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'lastReplayTimestamp': FieldValue.serverTimestamp(),
    });
  }

  // get user doc stream
  Stream<DocumentSnapshot> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // sign out
  Future<void> signOut() async {
    return await _auth.signOut();
  }

  // auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
