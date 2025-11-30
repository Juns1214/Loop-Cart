import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/showSnackBar.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

      // Create/update Firestore profile for Google sign-in
      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('user_profile')
            .doc(userCredential.user!.uid)
            .set(
              {
                'email': userCredential.user!.email,
                'name': userCredential.user!.displayName ?? '',
                'profileImageURL': userCredential.user!.photoURL ?? '',
                'phoneNumber': userCredential.user!.phoneNumber ?? '',
                'createdAt': FieldValue.serverTimestamp(),
              },
              SetOptions(merge: true),
            ); // merge: true to not overwrite existing data
      }

      return userCredential;
    } catch (e) {
      showSnackBar(context, e.toString());
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
