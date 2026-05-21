import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class WorkerAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      final userCred = await _auth.signInWithPopup(provider);
      return userCred.user;
    }
    final googleSignIn = GoogleSignIn();
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCred = await _auth.signInWithCredential(credential);
    return userCred.user;
  }

  Future<void> signOut() async {
    if (!kIsWeb) await GoogleSignIn().signOut();
    await _auth.signOut();
  }
}
