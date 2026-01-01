import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/utils/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'auth_method.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import '../../utils/router.dart';
import '../../widget/custom_text_field.dart';
import '../../widget/custom_button.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/signup",
      onGenerateRoute: onGenerateRoute,
    );
  }
}

class SignUpPage extends StatefulWidget {
  static MaterialPageRoute route() =>
      MaterialPageRoute(builder: (context) => const SignUpPage());
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<bool> _signUpUser() async {
    try {
      await AuthMethod(FirebaseAuth.instance).signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await _createUserProfile();
      Fluttertoast.showToast(msg: "Sign up successfully");
      return true;
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? "An error occurred");
      return false;
    }
  }

  Future<void> _createUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('user_profile')
          .doc(user.uid)
          .set({
            'email': user.email,
            'phoneNumber': '+60${_phoneController.text}',
            'createdAt': FieldValue.serverTimestamp(),
            'profileImageURL': '',
            'name': '',
            'address': '',
            'dateOfBirth': '',
            'greenCoins': 0,
          });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      // No context passed here anymore
      final userCredential = await AuthMethod(
        FirebaseAuth.instance,
      ).signInWithGoogle();

      if (userCredential != null) {
        Fluttertoast.showToast(msg: "Google sign-in successful");
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            "/mainpage",
            (route) => false,
          );
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Image.asset(
                'assets/images/icon/LogoIcon.png',
                height: 150,
                width: 150,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              const Text(
                "Create an account",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 25,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Start your circular shopping journey with us!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    CustomTextField(
                      controller: _emailController,
                      label: "Email",
                      hintText: "Please enter your email",
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _passwordController,
                      label: "Password",
                      hintText: "Please enter your password",
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter password";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: "Confirm Password",
                      hintText: "Please enter your password",
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter password";
                        } else if (value != _passwordController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      controller: _phoneController,
                      label: "Phone Number",
                      hintText: "Please enter your phone number",
                      keyboardType: TextInputType.phone,
                      prefixText: "+60 ",
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter phone number";
                        }
                        if (value.length < 9) {
                          return "Enter a valid phone number";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      text: "Sign Up",
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          bool signUpSuccess = await _signUpUser();
                          if (signUpSuccess && mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              "/setup-preference",
                              (route) => false,
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Other sign up options",
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: _handleGoogleSignIn,
                      customBorder: const CircleBorder(),
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/icon/google_icon.png',
                            height: 30,
                            width: 30,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          color: Colors.black,
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: "Sign In",
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              color: Color(0xFF1B5E20),
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushNamed(context, '/login');
                              },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
