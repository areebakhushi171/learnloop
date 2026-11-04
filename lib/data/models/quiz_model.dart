import 'package:cloud_firestore/cloud_firestore.dart';

class QuizQuestion {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  const QuizQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] ?? '',
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctOptionIndex: (map['correctOptionIndex'] as num?)?.toInt() ?? 0,
      explanation: map['explanation'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionText': questionText,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
      'explanation': explanation,
    };
  }
}

class QuizModel {
  final String id;
  final String courseId;
  final String? lessonId;
  final String title;
  final int timeLimitSeconds;
  final int passScorePercent;
  final List<QuizQuestion> questions;

  const QuizModel({
    required this.id,
    required this.courseId,
    this.lessonId,
    required this.title,
    this.timeLimitSeconds = 180,
    this.passScorePercent = 70,
    required this.questions,
  });

  factory QuizModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    final rawQuestions = (data['questions'] as List<dynamic>?) ?? [];
    return QuizModel(
      id: snapshot.id,
      courseId: data['courseId'] ?? '',
      lessonId: data['lessonId'],
      title: data['title'] ?? 'Module Assessment Quiz',
      timeLimitSeconds: (data['timeLimitSeconds'] as num?)?.toInt() ?? 180,
      passScorePercent: (data['passScorePercent'] as num?)?.toInt() ?? 70,
      questions: rawQuestions
          .map((q) => QuizQuestion.fromMap(q as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'courseId': courseId,
      'lessonId': lessonId,
      'title': title,
      'timeLimitSeconds': timeLimitSeconds,
      'passScorePercent': passScorePercent,
      'questions': questions.map((q) => q.toMap()).toList(),
    };
  }
}

class QuizAttemptModel {
  final String id;
  final String quizId;
  final String courseId;
  final int scorePercent;
  final int totalQuestions;
  final int correctQuestions;
  final Map<int, int> selectedAnswers;
  final int earnedXp;
  final DateTime completedAt;

  const QuizAttemptModel({
    required this.id,
    required this.quizId,
    required this.courseId,
    required this.scorePercent,
    required this.totalQuestions,
    required this.correctQuestions,
    required this.selectedAnswers,
    required this.earnedXp,
    required this.completedAt,
  });

  factory QuizAttemptModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    final rawAnswers = (data['selectedAnswers'] as Map<String, dynamic>?) ?? {};
    final parsedAnswers = rawAnswers.map(
      (key, value) => MapEntry(int.tryParse(key) ?? 0, (value as num).toInt()),
    );

    return QuizAttemptModel(
      id: snapshot.id,
      quizId: data['quizId'] ?? '',
      courseId: data['courseId'] ?? '',
      scorePercent: (data['scorePercent'] as num?)?.toInt() ?? 0,
      totalQuestions: (data['totalQuestions'] as num?)?.toInt() ?? 0,
      correctQuestions: (data['correctQuestions'] as num?)?.toInt() ?? 0,
      selectedAnswers: parsedAnswers,
      earnedXp: (data['earnedXp'] as num?)?.toInt() ?? 0,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final stringKeyAnswers = selectedAnswers.map(
      (key, value) => MapEntry(key.toString(), value),
    );
    return {
      'quizId': quizId,
      'courseId': courseId,
      'scorePercent': scorePercent,
      'totalQuestions': totalQuestions,
      'correctQuestions': correctQuestions,
      'selectedAnswers': stringKeyAnswers,
      'earnedXp': earnedXp,
      'completedAt': Timestamp.fromDate(completedAt),
    };
  }
}
