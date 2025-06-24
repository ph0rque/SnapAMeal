import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // auth & firestore instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  // sign in with email and password
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // sign up with email and password
  Future<UserCredential> signUpWithEmailPassword(
      String email, String password, String username) async {
    try {
      // create user
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // save user info in a separate doc
      await _firestore
          .collection("users")
          .doc(userCredential.user!.uid)
          .set({
            'uid': userCredential.user!.uid,
            'email': email,
            'username': username,
            'lastReplayTimestamp': null,
          });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // get user data
  Future<DocumentSnapshot> getUserData(String uid) {
    return _firestore.collection("users").doc(uid).get();
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
    await _firestore
        .collection('users')
        .doc(user.uid)
        .update({'lastReplayTimestamp': FieldValue.serverTimestamp()});
  }

  // sign out
  Future<void> signOut() async {
    return await _auth.signOut();
  }

  // auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
} 