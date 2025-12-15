import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../widget/custom_button.dart';
import 'quiz_main_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QuizStartPage(),
    );
  }
}

class QuizStartPage extends StatefulWidget {
  const QuizStartPage({super.key});

  @override
  State<QuizStartPage> createState() => _QuizStartPageState();
}

class _QuizStartPageState extends State<QuizStartPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isChecking = false;

  String _getTodayDateMalaysia() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    return DateFormat('yyyy-MM-dd').format(now);
  }

  Future<void> _handleStartQuiz() async {
    if (user == null) {
      _showErrorDialog('Please login to play the quiz');
      return;
    }

    setState(() => _isChecking = true);

    try {
      final todayDate = _getTodayDateMalaysia();
      final attemptId = '${user!.uid}_$todayDate';
      
      final doc = await FirebaseFirestore.instance
          .collection('quiz_attempts')
          .doc(attemptId)
          .get();

      if (doc.exists) {
        _showAlreadyPlayedDialog();
      } else {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuizPage()),
          );
        }
      }
    } catch (e) {
      _showErrorDialog('Error checking quiz status: $e');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _showAlreadyPlayedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF388E3C)),
            SizedBox(width: 12),
            Text('Already Played'),
          ],
        ),
        content: const Text(
          'You have already played today. Please come back tomorrow!',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF388E3C), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
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
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Daily Quiz',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF388E3C).withOpacity(0.3), width: 3),
                ),
                child: const Icon(
                  Icons.quiz_outlined,
                  size: 80,
                  color: Color(0xFF388E3C),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Daily Quiz Challenge',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Manrope',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Test your knowledge and earn 5 Green Coins!\nAnswer 6 questions from different categories.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.eco, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Earn 5 Green Coins',
                      style: TextStyle(
                        color: Colors.amber.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              CustomButton(
                text: 'Start Quiz',
                onPressed: _handleStartQuiz,
                isLoading: _isChecking,
                backgroundColor: const Color(0xFF388E3C),
                minimumSize: const Size(double.infinity, 56),
              ),
              const SizedBox(height: 16),
              Text(
                'You can play once per day',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}