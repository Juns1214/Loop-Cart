class QuizQuestion {
  final String id, question, correctAnswer, explanation, category;
  final List<String> options;

  QuizQuestion({required this.id, required this.question, required this.options, required this.correctAnswer, required this.explanation, required this.category});

  factory QuizQuestion.fromFirestore(String id, Map<String, dynamic> data) {
    List<String> options = List<String>.from(data['options'] ?? []);
    String correctString = data['correctAnswer'] ?? '';
    int correctIndex = options.indexOf(correctString);
    String correctLetter = correctIndex >= 0 ? String.fromCharCode(65 + correctIndex) : '';

    return QuizQuestion(
      id: id,
      category: data['category'] ?? '',
      question: data['question'] ?? '',
      options: options,
      correctAnswer: correctLetter,
      explanation: data['explanation'] ?? '',
    );
  }

  bool isCorrect(String answer) => answer == correctAnswer;
}