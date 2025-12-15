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
  Map<int, String> _userAnswers = {};
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

        if (querySnapshot.docs.isEmpty) {
          throw Exception('No questions found for category: $category');
        }

        // Randomly pick one question from this category
        final docs = querySnapshot.docs..shuffle(Random());
        final doc = docs.first;
        questions.add(QuizQuestion.fromFirestore(doc.id, doc.data()));
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

  void _selectAnswer(String answer) {
    setState(() {
      _userAnswers[_currentQuestionIndex] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions!.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _submitQuiz();
    }
  }

  void _submitQuiz() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => _showExitDialog(),
        ),
        title: const Text(
          'Daily Quiz',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF388E3C)))
          : _error != null
              ? _buildErrorView()
              : _buildQuizView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading quiz',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Go Back',
              onPressed: () => Navigator.pop(context),
              backgroundColor: const Color(0xFF388E3C),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizView() {
    final question = _questions![_currentQuestionIndex];
    final selectedAnswer = _userAnswers[_currentQuestionIndex];
    final isLastQuestion = _currentQuestionIndex == _questions!.length - 1;

    return Column(
      children: [
        // Progress Bar
        LinearProgressIndicator(
          value: (_currentQuestionIndex + 1) / _questions!.length,
          backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF388E3C)),
          minHeight: 6,
        ),
        
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Counter
                Text(
                  'Question ${_currentQuestionIndex + 1} of ${_questions!.length}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Category Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF388E3C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    question.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF388E3C),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Question Text
                Text(
                  question.question,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Answer Options
                ...question.options.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final optionLetter = String.fromCharCode(65 + index); // A, B, C, D
                  
                  return _QuizOptionTile(
                    letter: optionLetter,
                    text: option,
                    isSelected: selectedAnswer == optionLetter,
                    onTap: () => _selectAnswer(optionLetter),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        
        // Next/Submit Button
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
            backgroundColor: const Color(0xFF388E3C),
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
      ],
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Exit Quiz?'),
        content: const Text('Your progress will be lost. Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit quiz
            },
            child: const Text(
              'Exit',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizOptionTile extends StatelessWidget {
  final String letter;
  final String text;
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF388E3C).withOpacity(0.1) : Colors.grey[50],
            border: Border.all(
              color: isSelected ? const Color(0xFF388E3C) : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Radio Circle
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF388E3C) : Colors.grey[400]!,
                    width: 2,
                  ),
                  color: isSelected ? const Color(0xFF388E3C) : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Option Letter
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF388E3C) : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Option Text
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    color: isSelected ? Colors.black87 : Colors.black54,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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