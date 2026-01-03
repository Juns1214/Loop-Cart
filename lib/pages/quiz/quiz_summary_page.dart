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
  bool _isSaving = false, _saved = false;
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
      if (userAnswer != null && widget.questions[i].isCorrect(userAnswer))
        correct++;
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

      batch.update(
        FirebaseFirestore.instance.collection('user_profile').doc(user!.uid),
        {'greenCoins': FieldValue.increment(5)},
      );

      batch.set(
        FirebaseFirestore.instance
            .collection('green_coin_transactions')
            .doc(transactionId),
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
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving quiz: $e',
              style: const TextStyle(fontFamily: 'Roboto'),
            ),
            backgroundColor: const Color(0xFFD32F2F),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Quiz Results',
          style: TextStyle(
            fontFamily: 'Roboto',
            color: Color(0xFF212121),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF2E7D32),
                  const Color(0xFF2E7D32).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Quiz Complete!',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You got $_correctAnswers/${widget.questions.length} correct',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.eco, color: Color(0xFF2E7D32), size: 24),
                      SizedBox(width: 8),
                      Text(
                        '+5 Green Coins Earned!',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isSaving
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF2E7D32),
                      strokeWidth: 3,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.questions.length,
                    itemBuilder: (context, index) => _QuestionResultCard(
                      questionNumber: index + 1,
                      question: widget.questions[index],
                      userAnswer: widget.userAnswers[index],
                    ),
                  ),
          ),
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
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              backgroundColor: const Color(0xFF2E7D32),
              minimumSize: const Size(double.infinity, 56),
              borderRadius: 16,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Question $questionNumber',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isCorrect
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFD32F2F),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFD32F2F),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              question.question,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF212121),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ...question.options.asMap().entries.map((entry) {
              final optionLetter = String.fromCharCode(65 + entry.key);
              final isCorrectAnswer = question.correctAnswer == optionLetter;
              final isUserAnswer = userAnswer == optionLetter;
              return _AnswerOptionDisplay(
                letter: optionLetter,
                text: entry.value,
                isCorrectAnswer: isCorrectAnswer,
                isUserAnswer: isUserAnswer,
              );
            }),
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF1976D2).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFF1976D2),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Explanation',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1976D2),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          question.explanation,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            color: Color(0xFF212121),
                            fontWeight: FontWeight.w500,
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
  final String letter, text;
  final bool isCorrectAnswer, isUserAnswer;

  const _AnswerOptionDisplay({
    required this.letter,
    required this.text,
    required this.isCorrectAnswer,
    required this.isUserAnswer,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor, borderColor, textColor, letterBgColor;
    IconData? icon;

    if (isCorrectAnswer) {
      backgroundColor = const Color(0xFFE8F5E9);
      borderColor = const Color(0xFF66BB6A);
      textColor = const Color(0xFF1B5E20);
      letterBgColor = const Color(0xFF2E7D32);
      icon = Icons.check_circle;
    } else if (isUserAnswer) {
      backgroundColor = const Color(0xFFFFEBEE);
      borderColor = const Color(0xFFEF5350);
      textColor = const Color(0xFFB71C1C);
      letterBgColor = const Color(0xFFD32F2F);
      icon = Icons.cancel;
    } else {
      backgroundColor = const Color(0xFFF5F5F5);
      borderColor = const Color(0xFFE0E0E0);
      textColor = const Color(0xFF424242);
      letterBgColor = const Color(0xFFBDBDBD);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: letterBgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                letter,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
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
                fontFamily: 'Roboto',
                fontSize: 14,
                color: textColor,
                fontWeight: (isCorrectAnswer || isUserAnswer)
                    ? FontWeight.w700
                    : FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
          if (icon != null) ...[
            const SizedBox(width: 8),
            Icon(
              icon,
              color: isCorrectAnswer
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFD32F2F),
              size: 20,
            ),
          ],
        ],
      ),
    );
  }
}
