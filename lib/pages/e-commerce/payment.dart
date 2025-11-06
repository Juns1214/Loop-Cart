import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Payment(),
    );
  }
}

class Payment extends StatefulWidget {
  const Payment({super.key});

  @override
  State<Payment> createState() => _PaymentState();
}

class _PaymentState extends State<Payment> {
  String selectedPayment = 'Visa';

  Widget paymentMethodContainer(
    String paymentLogo,
    String paymentMethod,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPayment = paymentMethod;
        });
      },
      child: Container(
        height: 60,
        width: 350,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Image.asset(paymentLogo, height: 50, width: 55, fit: BoxFit.fill),
            const SizedBox(width: 40),
            Text(paymentMethod),
            const Spacer(),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF2E5BFF) : Colors.white,
                border: Border.all(
                  color: isSelected ? const Color(0xFF2E5BFF) : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Payment Method',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  paymentMethodContainer('assets/images/icon/VISA.png', 'Visa', selectedPayment == 'Visa'),
                  paymentMethodContainer('assets/images/icon/Paypal.png', 'PayPal', selectedPayment == 'PayPal'),
                  paymentMethodContainer('assets/images/icon/Online_Transfer.png', 'Bank Transfer', selectedPayment == 'Bank Transfer'),
                  paymentMethodContainer('assets/images/icon/TNG.png', 'Touch n Go', selectedPayment == 'Touch n Go'),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Other Methods',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Center(
              child: paymentMethodContainer(
                'assets/images/icon/cash-on-delivery-icon.png',
                'Cash on Delivery',
                selectedPayment == 'Cash on Delivery',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.payments_outlined),
                label: const Text("Make Payment"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E5BFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}