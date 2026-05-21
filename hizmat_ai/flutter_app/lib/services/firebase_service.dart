import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

Future<User?> signInWithGoogle() async {
  if (kIsWeb) {
    final provider = GoogleAuthProvider();
    final userCred = await FirebaseAuth.instance.signInWithPopup(provider);
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
  final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
  return userCred.user;
}

Future<void> signOut() async {
  if (!kIsWeb) await GoogleSignIn().signOut();
  await FirebaseAuth.instance.signOut();
}
