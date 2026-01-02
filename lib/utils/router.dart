import 'package:flutter/material.dart';
import '../main.dart';
import '../pages/auth/onboarding_page.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/signup_page.dart';
import '../pages/e-commerce/main_page.dart';
import '../pages/preference/setup_preference.dart';
import '../pages/checkout/shopping_cart.dart';
import '../pages/checkout/checkout.dart';
import '../pages/checkout/payment.dart';
import '../pages/checkout/payment_confirmation.dart';
import '../pages/checkout/my_activity.dart';
import '../pages/feature/chatbot.dart';
import '../pages/feature/donation.dart';
import '../pages/feature/recycling_pickup.dart';
import '../pages/feature/repair_service.dart';
import '../pages/feature/sell_second_hand_product.dart';
import '../pages/feature/sustainability_dashboard.dart';
import '../pages/user_profile/user_profile.dart';
import '../pages/user_profile/edit_profile.dart';
import '../pages/e-commerce/preowned_main_page.dart';
import '../pages/e-commerce/category_filter.dart';
import '../pages/quiz/quiz_start_page.dart';
import './../pages/feature/green_coin.dart';
import '../pages/feature/waste_sorting_assistant.dart';
import '../pages/e-commerce/product_page.dart';

//1. Set up routes
final Map routes = {
  "/start": (context) => const GetStartedPage(),
  "/onboarding": (context) => const OnboardingPage(),
  "/login": (context) => const LoginPage(),
  "/signup": (context) => const SignUpPage(),
  "/mainpage": (context) => const MainPage(),
  "/setup-preference": (context) => const SetupPreferencePage(),
  "/shopping-cart": (context) => ShoppingCart(),
  "/checkout": (context, {arguments}) => Checkout(
    selectedItems: List<Map<String, dynamic>>.from(
        arguments['selectedItems'].map((item) => item as Map<String, dynamic>)
    ),
    userAddress: arguments['userAddress'] is Map<String, dynamic>
        ? arguments['userAddress'] as Map<String, dynamic>
        : null,
  ),
  "/payment": (context, {arguments}) =>
      Payment(orderData: arguments as Map<String, dynamic>? ?? {}),
  "/payment-confirmation": (context) => PaymentConfirmation(
    orderData: {},
    orderId: '',
    transactionId: '',
    paymentMethod: '',
  ),
  "/my-activity": (context) => const MyActivityPage(),
  "/chatbot": (context) => const ChatBotScreen(),
  "/donation": (context) => const DonationPage(),
  "/recycling-pickup": (context) => const RecyclingPickUpPage(),
  "/repair-service": (context) => const RepairServicePage(),
  "/sell-second-hand-product": (context) => const SellItemPage(),
  "/sustainability-dashboard": (context) => const DashboardPage(),
  "/user-profile": (context) => const UserProfile(),
  "/edit-profile": (context) => const EditProfile(),
  "/preowned-main-page": (context) => const PreownedMainPage(),
  "/category-filter": (context) => const CategoryFilterPage(),
  "/quiz-start-page": (context) => const QuizStartPage(),
  "/green-coin": (context) => const GreenCoinPage(),
  "/waste-sorting-assistant": (context) => const WasteClassificationPage(),
  "/product-details": (context, {arguments}) {
    final args = arguments as Map<String, dynamic>? ?? {};
    return ProductPage(
      product: args['product'] as Map<String, dynamic>,
      isPreowned: args['isPreowned'] as bool? ?? false,
    );
  },
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
