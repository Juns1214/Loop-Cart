import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/showSnackBar.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthMethod {
  final FirebaseAuth _auth;
  AuthMethod(this._auth);

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String phoneNumber,
    required BuildContext context,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, e.message ?? 'An error occurred');
      rethrow;
    }
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, e.message ?? "Login failed");
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        showSnackBar(context, "Google sign-in cancelled");
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      return userCredential;
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, e.message ?? "Google sign-in failed");
      return null;
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();

    } on FirebaseAuthException catch (e) {
      showSnackBar(context, e.message!); 
    }
  }

  Future<void> deleteAccount(BuildContext context) async {
    try {
      await _auth.currentUser!.delete();
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, e.message!);
    }
  }
}
