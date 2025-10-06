import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/showSnackBar.dart';

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
          password: password,);
    } on FirebaseAuthException catch (e) {
      showSnackBar(context, e.message ?? 'An error occurred');
      rethrow;
    }
  }
}