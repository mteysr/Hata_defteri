class AcademyQuestion {
  final int id;
  final String category;
  final String topic;
  final String difficulty;
  final String question;
  final List<String> options;
  final int correctAnswer;
  final String explanation;

  AcademyQuestion({
    required this.id,
    required this.category,
    required this.topic,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
  });

  factory AcademyQuestion.fromJson(Map<String, dynamic> json) {
    return AcademyQuestion(
      id: json['id'] as int,
      category: json['category'] as String,
      topic: json['topic'] as String,
      difficulty: json['difficulty'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options']),
      correctAnswer: json['correctAnswer'] as int,
      explanation: json['explanation'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'topic': topic,
      'difficulty': difficulty,
      'question': question,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
    };
  }
}
