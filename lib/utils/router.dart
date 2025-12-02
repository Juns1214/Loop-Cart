import 'package:flutter/material.dart';
import '../pages/auth/start_page.dart';
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
import '../pages/e-commerce/category_filter.dart';
import '../pages/checkout/order_status.dart';

//1. Set up routes
final Map routes = {
  "/start": (context) => const GetStartedPage(),
  "/onboarding": (context) => const OnboardingPage(),
  "/login": (context) => const LoginPage(),
  "/signup": (context) => const SignUpPage(),
  "/mainpage": (context) => const MainPage(),
  "/setup-preference": (context) => const SetupPreferencePage(),
  "/category-filter": (context) => const CategoryFilterPage(),
  "/shopping-cart": (context) => ShoppingCart(),
  "/checkout": (context, {arguments}) => Checkout(
    selectedItems: arguments['selectedItems'] as List<Map<String, dynamic>>,
    userAddress: arguments['userAddress'] as Map<String, dynamic>?,
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
  "/order-status": (context, {arguments}) =>
      OrderStatus(orderId: arguments['orderId'] as String),
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
