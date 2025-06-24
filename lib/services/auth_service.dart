import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // auth instance
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
  Future<UserCredential> signUpWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.code);
    }
  }

  // sign out
  Future<void> signOut() async {
    return await _auth.signOut();
  }

  // auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
} 