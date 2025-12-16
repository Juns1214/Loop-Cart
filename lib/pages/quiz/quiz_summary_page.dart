import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'quiz_model.dart';
import '../../widget/custom_button.dart';

class QuizSummaryPage extends StatefulWidget {
  final List<QuizQuestion> questions;
  final Map<int, String> userAnswers;

  const QuizSummaryPage({
    super.key,
    required this.questions,
    required this.userAnswers,
  });

  @override
  State<QuizSummaryPage> createState() => _QuizSummaryPageState();
}

class _QuizSummaryPageState extends State<QuizSummaryPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool _isSaving = false;
  bool _saved = false;
  int _correctAnswers = 0;

  @override
  void initState() {
    super.initState();
    _calculateScore();
    _saveQuizAttempt();
  }

  void _calculateScore() {
    int correct = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      final userAnswer = widget.userAnswers[i];
      if (userAnswer != null && widget.questions[i].isCorrect(userAnswer)) {
        correct++;
      }
    }
    _correctAnswers = correct;
  }

  String _getTodayDateMalaysia() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    return DateFormat('yyyy-MM-dd').format(now);
  }

  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'TXN$timestamp$random';
  }

  Future<void> _saveQuizAttempt() async {
    if (user == null || _saved) return;

    setState(() => _isSaving = true);

    try {
      final todayDate = _getTodayDateMalaysia();
      final attemptId = '${user!.uid}_$todayDate';
      final transactionId = _generateTransactionId();

      final batch = FirebaseFirestore.instance.batch();

      // Create quiz attempt
      batch.set(
        FirebaseFirestore.instance.collection('quiz_attempts').doc(attemptId),
        {
          'userId': user!.uid,
          'date': todayDate,
          'completedAt': FieldValue.serverTimestamp(),
          'questionsAnswered': widget.questions.length,
          'correctAnswers': _correctAnswers,
        },
      );

      // Update user coins
      batch.update(
        FirebaseFirestore.instance.collection('user_profile').doc(user!.uid),
        {'greenCoins': FieldValue.increment(5)},
      );

      // Create transaction record
      batch.set(
        FirebaseFirestore.instance.collection('green_coin_transactions').doc(transactionId),
        {
          'transactionId': transactionId,
          'userId': user!.uid,
          'amount': 5,
          'activity': 'daily_quiz',
          'description': 'Daily Quiz Completed',
          'createdAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      setState(() {
        _saved = true;
        _isSaving = false;
      });
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving quiz: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Quiz Results',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Score Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF388E3C),
                  const Color(0xFF388E3C).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Quiz Complete!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You got $_correctAnswers/${widget.questions.length} correct',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.eco, color: Color(0xFF388E3C), size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        '+5 Green Coins Earned!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF388E3C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Results List
          Expanded(
            child: _isSaving
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF388E3C)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.questions.length,
                    itemBuilder: (context, index) {
                      return _QuestionResultCard(
                        questionNumber: index + 1,
                        question: widget.questions[index],
                        userAnswer: widget.userAnswers[index],
                      );
                    },
                  ),
          ),

          // Done Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: CustomButton(
              text: 'Done',
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              backgroundColor: const Color(0xFF388E3C),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionResultCard extends StatelessWidget {
  final int questionNumber;
  final QuizQuestion question;
  final String? userAnswer;

  const _QuestionResultCard({
    required this.questionNumber,
    required this.question,
    required this.userAnswer,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = userAnswer != null && question.isCorrect(userAnswer!);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Question $questionNumber',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.red,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question Text
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Answer Options
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final optionLetter = String.fromCharCode(65 + index);
              final isCorrectAnswer = question.correctAnswer == optionLetter;
              final isUserAnswer = userAnswer == optionLetter;

              return _AnswerOptionDisplay(
                letter: optionLetter,
                text: option,
                isCorrectAnswer: isCorrectAnswer,
                isUserAnswer: isUserAnswer,
              );
            }),

            // Explanation
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explanation',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          question.explanation,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade900,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
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

class _AnswerOptionDisplay extends StatelessWidget {
  final String letter;
  final String text;
  final bool isCorrectAnswer;
  final bool isUserAnswer;

  const _AnswerOptionDisplay({
    required this.letter,
    required this.text,
    required this.isCorrectAnswer,
    required this.isUserAnswer,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    IconData? icon;

    if (isCorrectAnswer) {
      backgroundColor = Colors.green.shade50;
      borderColor = Colors.green.shade300;
      textColor = Colors.green.shade900;
      icon = Icons.check_circle;
    } else if (isUserAnswer) {
      backgroundColor = Colors.red.shade50;
      borderColor = Colors.red.shade300;
      textColor = Colors.red.shade900;
      icon = Icons.cancel;
    } else {
      backgroundColor = Colors.grey.shade50;
      borderColor = Colors.grey.shade300;
      textColor = Colors.grey.shade700;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCorrectAnswer ? Colors.green : (isUserAnswer ? Colors.red : Colors.grey),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                letter,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                fontWeight: (isCorrectAnswer || isUserAnswer) ? FontWeight.w600 : FontWeight.normal,
                height: 1.3,
              ),
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(icon, color: isCorrectAnswer ? Colors.green : Colors.red, size: 20),
          ],
        ],
      ),
    );
  }
}