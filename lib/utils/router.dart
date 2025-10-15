import 'package:flutter/material.dart';
import '../pages/auth/start_page.dart';
import '../pages/auth/onboarding_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/signup_page.dart';
import '../pages/e-commerce/main_page.dart';
import '../pages/preference/setup_preference.dart';




  //1. Set up routes
  final Map routes = {
    "/start": (context) => const GetStartedPage(),
    "/onboarding": (context) => const OnboardingPage(),
    "/login": (context) => const LoginPage(),
    "/signup": (context) => const SignUpPage(),
    "/mainpage": (context) => const MainPage(),
    "/setup-preference": (context) => const SetupPreferencePage(),
  };

  //2. Set up Route Generator (FIXED)
  var onGenerateRoute = (RouteSettings settings) {
    final String? name = settings.name; 
    final Function? pageContentBuilder = routes[name]; 
    if (pageContentBuilder != null) {
      if (settings.arguments != null) {
        final Route route = MaterialPageRoute(
          builder: (context) =>
              pageContentBuilder(context, arguments: settings.arguments),
        );
        return route;
      } else {
        final Route route = MaterialPageRoute(
          builder: (context) => pageContentBuilder(context),
        );
        return route;
      }
    }
    return null;
  };
