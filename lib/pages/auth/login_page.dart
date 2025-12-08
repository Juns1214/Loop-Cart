import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import '../../utils/router.dart';
import 'auth_method.dart';
import 'package:flutter_application_1/utils/firebase_options.dart';
import '../../widget/custom_text_field.dart';
import '../../widget/custom_button.dart';
import '../../widget/logo_widget.dart';
import '../../widget/social_signin_button.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/login",
      onGenerateRoute: onGenerateRoute,
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<bool> _userLogin() async {
    try {
      await AuthMethod(FirebaseAuth.instance).loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      Fluttertoast.showToast(msg: "Login successful");
      return true;
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? "An error occurred");
      return false;
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
              const LogoWidget(size: 250),
              const SizedBox(height: 20),
              const Text(
                "Hi, Welcome Back! 👋",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 25,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Hello again, you've been missed!",
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
                    CustomButton(
                      text: "Login",
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          bool loginSuccess = await _userLogin();
                          if (loginSuccess && mounted) {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              "/mainpage",
                              (route) => false,
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Other sign in options",
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 17,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SocialSignInButton(
                      iconPath: 'assets/images/icon/google_icon.png',
                      onTap: _handleGoogleSignIn,
                    ),
                    const SizedBox(height: 40),
                    RichText(
                      text: TextSpan(
                        text: "Don't have an account yet? ",
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          color: Colors.black,
                          fontSize: 17.0,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: "Sign Up",
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              color: Color(0xFF1B5E20),
                              fontSize: 17.0,
                              fontWeight: FontWeight.bold,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushNamed(context, '/signup');
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