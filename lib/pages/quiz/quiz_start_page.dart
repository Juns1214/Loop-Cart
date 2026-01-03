import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../widget/custom_button.dart';
import 'quiz_main_page.dart';

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
      _showDialog('Error', 'Please login to play the quiz');
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
        _showDialog(
          'Already Played',
          'You have already played today. Please come back tomorrow!',
          isInfo: true,
        );
      } else {
        if (mounted)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuizPage()),
          );
      }
    } catch (e) {
      _showDialog('Error', 'Error checking quiz status: $e');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _showDialog(String title, String message, {bool isInfo = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            if (isInfo)
              const Icon(Icons.info_outline, color: Color(0xFF2E7D32)),
            if (isInfo) const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Color(0xFF212121),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF424242),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF212121)),
        title: const Text(
          'Daily Quiz',
          style: TextStyle(
            fontFamily: 'Roboto',
            color: Color(0xFF212121),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
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
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF2E7D32).withOpacity(0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.quiz_outlined,
                  size: 80,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Daily Quiz Challenge',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B5E20),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Test your knowledge and earn 5 Green Coins!\nAnswer 6 questions from different categories.',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  color: Color(0xFF424242),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF9C4), Color(0xFFFFF59D)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFDD835), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: Color(0xFF2E7D32),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Earn 5 Green Coins',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: Color(0xFF212121),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
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
                backgroundColor: const Color(0xFF2E7D32),
                minimumSize: const Size(double.infinity, 56),
                borderRadius: 16,
              ),
              const SizedBox(height: 16),
              const Text(
                'You can play once per day',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: Color(0xFF424242),
                  fontWeight: FontWeight.w600,
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
