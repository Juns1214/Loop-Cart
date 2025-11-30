import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import '../../utils/router.dart';
import 'auth_method.dart';
import 'package:flutter_application_1/utils/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/login",
      onGenerateRoute: onGenerateRoute,    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<bool> userLogin() async {
    try {
      print("Attempting login...");
      await AuthMethod(FirebaseAuth.instance).loginWithEmail(
        email: emailController.text,
        password: passwordController.text,
        context: context,
      );
      print("Login successful!"); 
      Fluttertoast.showToast(msg: "Login successful");
      return true;
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? "An error occurred");
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        height: double.infinity,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            SizedBox(height: 10),
            Image.asset(
              'assets/images/icon/LogoIcon.png',
              height: 250,
              width: 250,
              fit: BoxFit.contain,
            ),
            SizedBox(height: 20),

            Text(
              "Hi, Welcome Back!👋",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 25,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),

            Text(
              "Hello again, you’ve been missed!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            SizedBox(height: 40),

            Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Email",
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Please enter your email",
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter email";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Password",
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        color: Color(0xFF1B5E20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Please enter your password",
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter password";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20.0),

                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        bool loginSuccess = await userLogin();
                        if (loginSuccess) {
                          Navigator.pushNamedAndRemoveUntil(context, "/mainpage", (route) => false);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                      backgroundColor: Color(0xFF388E3C),
                      minimumSize: Size(250, 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      "Login",
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  SizedBox(height: 30.0),

                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Other sign in options",
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 17,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 20.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () async {
                              final userCredential = await AuthMethod(FirebaseAuth.instance).signInWithGoogle(context);
                              if (userCredential != null) {
                                Fluttertoast.showToast(msg: "Google sign-in successful");
                                Navigator.pushNamedAndRemoveUntil(context, "/mainpage", (route) => false);

                              }
                            },

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
                        ],
                      ),

                      SizedBox(height: 40.0),

                      RichText(
                        text: TextSpan(
                          text: "Don't have an account yet? ",
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            color: Colors.black,
                            fontSize: 17.0,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: "Sign Up",
                              style: TextStyle(
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
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
