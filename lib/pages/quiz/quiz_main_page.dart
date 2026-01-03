import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'quiz_model.dart';
import '../../widget/custom_button.dart';
import 'quiz_summary_page.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final List<String> _categories = [
    'Sustainability Basics',
    'Recycling & Waste Sorting',
    'Linear Economy vs Circular Economy',
    'Repair, Reuse & Second-Life',
    'Social Awareness',
    'Environment & Pollution',
  ];

  List<QuizQuestion>? _questions;
  final Map<int, String> _userAnswers = {};
  int _currentQuestionIndex = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    try {
      List<QuizQuestion> questions = [];
      for (String category in _categories) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('questions')
            .where('category', isEqualTo: category)
            .get();
        if (querySnapshot.docs.isEmpty)
          throw Exception('No questions found for category: $category');
        final docs = querySnapshot.docs..shuffle(Random());
        questions.add(
          QuizQuestion.fromFirestore(docs.first.id, docs.first.data()),
        );
      }
      setState(() {
        _questions = questions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectAnswer(String answer) =>
      setState(() => _userAnswers[_currentQuestionIndex] = answer);

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions!.length - 1) {
      setState(() => _currentQuestionIndex++);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizSummaryPage(
            questions: _questions!,
            userAnswers: _userAnswers,
          ),
        ),
      );
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Exit Quiz?',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF212121),
          ),
        ),
        content: const Text(
          'Your progress will be lost. Are you sure you want to exit?',
          style: TextStyle(
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
              'Cancel',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: Color(0xFF616161),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              'Exit',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: Color(0xFFD32F2F),
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
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF212121)),
          onPressed: _showExitDialog,
        ),
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2E7D32),
                strokeWidth: 3,
              ),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Color(0xFFD32F2F),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading quiz',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        color: Color(0xFF424242),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Go Back',
                      onPressed: () => Navigator.pop(context),
                      backgroundColor: const Color(0xFF2E7D32),
                      borderRadius: 12,
                    ),
                  ],
                ),
              ),
            )
          : _buildQuizView(),
    );
  }

  Widget _buildQuizView() {
    final question = _questions![_currentQuestionIndex];
    final selectedAnswer = _userAnswers[_currentQuestionIndex];
    final isLastQuestion = _currentQuestionIndex == _questions!.length - 1;

    return Column(
      children: [
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / _questions!.length,
          backgroundColor: const Color(0xFFE0E0E0),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
          minHeight: 6,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${_questions!.length}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: Color(0xFF424242),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    question.category,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  question.question,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF212121),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                ...question.options.asMap().entries.map((entry) {
                  final optionLetter = String.fromCharCode(65 + entry.key);
                  return _QuizOptionTile(
                    letter: optionLetter,
                    text: entry.value,
                    isSelected: selectedAnswer == optionLetter,
                    onTap: () => _selectAnswer(optionLetter),
                  );
                }),
              ],
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
            text: isLastQuestion ? 'Submit Quiz' : 'Next Question',
            onPressed: selectedAnswer != null ? _nextQuestion : () {},
            backgroundColor: selectedAnswer != null
                ? const Color(0xFF2E7D32)
                : const Color(0xFFBDBDBD),
            minimumSize: const Size(double.infinity, 56),
            borderRadius: 16,
          ),
        ),
      ],
    );
  }
}

class _QuizOptionTile extends StatelessWidget {
  final String letter, text;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuizOptionTile({
    required this.letter,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2E7D32).withOpacity(0.08)
                : Colors.white,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFFE0E0E0),
              width: isSelected ? 2 : 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF2E7D32).withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFBDBDBD),
                    width: 2,
                  ),
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFF5F5F5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFE0E0E0),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF212121),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    color: const Color(0xFF212121),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
