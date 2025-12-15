class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String category;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.category,
  });

factory QuizQuestion.fromFirestore(String id, Map<String, dynamic> data) {
  List<String> options = List<String>.from(data['options'] ?? []);
  String correctString = data['correctAnswer'] ?? '';
  
  // --- THE FIX STARTS HERE ---
  // Find which index (0, 1, 2, 3) contains the correct string
  int correctIndex = options.indexOf(correctString);
  
  // Convert that index to a letter (0 -> A, 1 -> B, etc.)
  // If the string isn't found, default to empty or handle error
  String correctLetter = correctIndex >= 0 
      ? String.fromCharCode(65 + correctIndex) 
      : ''; 
  // --- THE FIX ENDS HERE ---

  return QuizQuestion(
    id: id,
    category: data['category'] ?? '',
    question: data['question'] ?? '',
    options: options,
    // Store the LETTER 'A', not the string "Using resources..."
    correctAnswer: correctLetter, 
    explanation: data['explanation'] ?? '',
  );
}

  bool isCorrect(String answer) => answer == correctAnswer;
}