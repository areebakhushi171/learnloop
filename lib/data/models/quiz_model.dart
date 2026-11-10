import 'package:cloud_firestore/cloud_firestore.dart';

enum QuestionType { mcq, multiSelect, trueFalse, shortAnswer, longAnswer }
enum ScoringAttempt { best, latest }
enum GradingMode { auto, manual, mixed }
enum ShowResultsMode { immediately, afterGrading, afterDeadline }
enum AttemptStatus { inProgress, submitted, graded, missed }
enum ExtensionStatus { pending, approved, rejected }

class QuizQuestionModel {
  final String id;
  final QuestionType type;
  final String text;
  final String? imageUrl;
  final List<String> options;
  final List<int> correctIndexes;
  final int marks;
  final String explanation;
  final String topic;
  final int order;

  const QuizQuestionModel({
    required this.id,
    required this.type,
    required this.text,
    this.imageUrl,
    required this.options,
    required this.correctIndexes,
    required this.marks,
    required this.explanation,
    required this.topic,
    required this.order,
  });

  String get questionText => text;
  int get correctIndex => correctIndexes.isNotEmpty ? correctIndexes.first : 0;

  factory QuizQuestionModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return QuizQuestionModel(
      id: snapshot.id,
      type: QuestionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => QuestionType.mcq,
      ),
      text: data['text'] ?? data['questionText'] ?? '',
      imageUrl: data['imageUrl'],
      options: List<String>.from(data['options'] ?? []),
      correctIndexes: List<int>.from((data['correctIndexes'] as List?)?.map((e) => (e as num).toInt()) ?? [data['correctIndex'] ?? 0]),
      marks: (data['marks'] as num?)?.toInt() ?? 1,
      explanation: data['explanation'] ?? '',
      topic: data['topic'] ?? 'General',
      order: (data['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'text': text,
      'imageUrl': imageUrl,
      'options': options,
      'correctIndexes': correctIndexes,
      'marks': marks,
      'explanation': explanation,
      'topic': topic,
      'order': order,
    };
  }
}

class QuizModel {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String instructions;
  final int order;
  final int totalMarks;
  final int passingMarks;
  final int timeLimitMinutes;
  final DateTime? startAt;
  final DateTime? dueAt;
  final int maxAttempts;
  final ScoringAttempt scoringAttempt;
  final GradingMode gradingMode;
  final bool shuffleQuestions;
  final bool shuffleOptions;
  final ShowResultsMode showResultsMode;
  final bool allowExtensionRequests;
  final bool isPublished;
  final int questionCount;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<QuizQuestionModel> questions;

  const QuizModel({
    required this.id,
    required this.courseId,
    required this.title,
    required this.description,
    required this.instructions,
    required this.order,
    required this.totalMarks,
    required this.passingMarks,
    required this.timeLimitMinutes,
    this.startAt,
    this.dueAt,
    required this.maxAttempts,
    required this.scoringAttempt,
    required this.gradingMode,
    required this.shuffleQuestions,
    required this.shuffleOptions,
    required this.showResultsMode,
    required this.allowExtensionRequests,
    required this.isPublished,
    required this.questionCount,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.questions = const [],
  });

  int get totalQuestions => questionCount;
  int get passScorePercent => totalMarks > 0 ? ((passingMarks / totalMarks) * 100).toInt() : 70;
  int get timeLimitSeconds => timeLimitMinutes * 60;
  int get passingScore => passingMarks;

  QuizModel copyWithQuestions(List<QuizQuestionModel> newQuestions) {
    return QuizModel(
      id: id,
      courseId: courseId,
      title: title,
      description: description,
      instructions: instructions,
      order: order,
      totalMarks: newQuestions.fold<int>(0, (acc, q) => acc + q.marks),
      passingMarks: passingMarks,
      timeLimitMinutes: timeLimitMinutes,
      startAt: startAt,
      dueAt: dueAt,
      maxAttempts: maxAttempts,
      scoringAttempt: scoringAttempt,
      gradingMode: gradingMode,
      shuffleQuestions: shuffleQuestions,
      shuffleOptions: shuffleOptions,
      showResultsMode: showResultsMode,
      allowExtensionRequests: allowExtensionRequests,
      isPublished: isPublished,
      questionCount: newQuestions.length,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      questions: newQuestions,
    );
  }

  factory QuizModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, {List<QuizQuestionModel>? questions}) {
    final data = snapshot.data() ?? {};
    return QuizModel(
      id: snapshot.id,
      courseId: data['courseId'] ?? '',
      title: data['title'] ?? 'Quiz',
      description: data['description'] ?? '',
      instructions: data['instructions'] ?? '',
      order: (data['order'] as num?)?.toInt() ?? 0,
      totalMarks: (data['totalMarks'] as num?)?.toInt() ?? (data['totalQuestions'] as num?)?.toInt() ?? 100,
      passingMarks: (data['passingMarks'] as num?)?.toInt() ?? 70,
      timeLimitMinutes: (data['timeLimitMinutes'] as num?)?.toInt() ?? ((data['timeLimitSeconds'] as num?) != null ? ((data['timeLimitSeconds'] as num).toInt() ~/ 60) : 30),
      startAt: (data['startAt'] as Timestamp?)?.toDate(),
      dueAt: (data['dueAt'] as Timestamp?)?.toDate(),
      maxAttempts: (data['maxAttempts'] as num?)?.toInt() ?? 1,
      scoringAttempt: ScoringAttempt.values.firstWhere(
        (e) => e.name == data['scoringAttempt'],
        orElse: () => ScoringAttempt.best,
      ),
      gradingMode: GradingMode.values.firstWhere(
        (e) => e.name == data['gradingMode'],
        orElse: () => GradingMode.auto,
      ),
      shuffleQuestions: data['shuffleQuestions'] ?? true, // Defaults to TRUE for shuffling
      shuffleOptions: data['shuffleOptions'] ?? true,     // Defaults to TRUE for shuffling
      showResultsMode: ShowResultsMode.values.firstWhere(
        (e) => e.name == data['showResultsMode'],
        orElse: () => ShowResultsMode.immediately,
      ),
      allowExtensionRequests: data['allowExtensionRequests'] ?? true,
      isPublished: data['isPublished'] ?? true,
      questionCount: (data['questionCount'] as num?)?.toInt() ?? (data['totalQuestions'] as num?)?.toInt() ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      questions: questions ?? const [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'instructions': instructions,
      'order': order,
      'totalMarks': totalMarks,
      'passingMarks': passingMarks,
      'timeLimitMinutes': timeLimitMinutes,
      'startAt': startAt != null ? Timestamp.fromDate(startAt!) : null,
      'dueAt': dueAt != null ? Timestamp.fromDate(dueAt!) : null,
      'maxAttempts': maxAttempts,
      'scoringAttempt': scoringAttempt.name,
      'gradingMode': gradingMode.name,
      'shuffleQuestions': shuffleQuestions,
      'shuffleOptions': shuffleOptions,
      'showResultsMode': showResultsMode.name,
      'allowExtensionRequests': allowExtensionRequests,
      'isPublished': isPublished,
      'questionCount': questionCount,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class QuizAttemptModel {
  final String id;
  final String courseId;
  final String quizId;
  final int attemptNumber;
  final AttemptStatus status;
  final DateTime startedAt;
  final DateTime? submittedAt;
  final DateTime? deadlineAt;
  final int timeTakenSeconds;
  final Map<String, dynamic> answers; // questionId -> original selected indexes
  final Map<String, List<int>> optionOrder; // questionId -> list of original option indexes in displayed order
  final List<String> questionOrder; // list of questionIds in displayed order
  final int autoScore;
  final int manualScore;
  final int totalScore;
  final int totalMarks;
  final double percentage;
  final bool passed;
  final Map<String, int> perQuestionMarks;
  final Map<String, String> perQuestionFeedback;
  final String? feedback;
  final String? gradedBy;
  final DateTime? gradedAt;
  final bool isLate;
  final DateTime createdAt;

  QuizAttemptModel({
    required this.id,
    required this.courseId,
    required this.quizId,
    this.attemptNumber = 1,
    this.status = AttemptStatus.submitted,
    DateTime? startedAt,
    this.submittedAt,
    this.deadlineAt,
    this.timeTakenSeconds = 0,
    required this.answers,
    this.optionOrder = const {},
    this.questionOrder = const [],
    int? autoScore,
    this.manualScore = 0,
    int? totalScore,
    int? totalMarks,
    double? percentage,
    required this.passed,
    this.perQuestionMarks = const {},
    this.perQuestionFeedback = const {},
    this.feedback,
    this.gradedBy,
    this.gradedAt,
    this.isLate = false,
    DateTime? createdAt,
    double? score,
    int? correctCount,
    int? totalQuestions,
  })  : startedAt = startedAt ?? createdAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now(),
        autoScore = autoScore ?? correctCount ?? 0,
        totalScore = totalScore ?? correctCount ?? 0,
        totalMarks = totalMarks ?? totalQuestions ?? 100,
        percentage = percentage ?? score ?? 0.0;

  double get score => percentage;
  int get correctCount => autoScore;
  int get scorePercent => percentage.toInt();
  int get correctQuestions => autoScore;
  int get totalQuestions => totalMarks;
  Map<int, int> get selectedAnswers => answers.map((k, v) => MapEntry(int.tryParse(k) ?? 0, v is List && v.isNotEmpty ? v.first : 0));
  int get earnedXp => passed ? (totalScore * 10) + 100 : (totalScore * 10);
  DateTime get completedAt => createdAt;

  factory QuizAttemptModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    
    // Parse stored optionOrder
    final rawOptionOrder = (data['optionOrder'] as Map<String, dynamic>?) ?? {};
    final parsedOptionOrder = rawOptionOrder.map(
      (k, v) => MapEntry(k, List<int>.from((v as List).map((e) => (e as num).toInt()))),
    );

    return QuizAttemptModel(
      id: snapshot.id,
      courseId: data['courseId'] ?? '',
      quizId: data['quizId'] ?? '',
      attemptNumber: (data['attemptNumber'] as num?)?.toInt() ?? 1,
      status: AttemptStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AttemptStatus.submitted,
      ),
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate(),
      deadlineAt: (data['deadlineAt'] as Timestamp?)?.toDate(),
      timeTakenSeconds: (data['timeTakenSeconds'] as num?)?.toInt() ?? 0,
      answers: Map<String, dynamic>.from(data['answers'] ?? data['selectedAnswers'] ?? {}),
      optionOrder: parsedOptionOrder,
      questionOrder: List<String>.from(data['questionOrder'] ?? []),
      autoScore: (data['autoScore'] as num?)?.toInt() ?? (data['correctCount'] as num?)?.toInt() ?? 0,
      manualScore: (data['manualScore'] as num?)?.toInt() ?? 0,
      totalScore: (data['totalScore'] as num?)?.toInt() ?? (data['correctCount'] as num?)?.toInt() ?? 0,
      totalMarks: (data['totalMarks'] as num?)?.toInt() ?? (data['totalQuestions'] as num?)?.toInt() ?? 100,
      percentage: (data['percentage'] as num?)?.toDouble() ?? (data['score'] as num?)?.toDouble() ?? 0.0,
      passed: data['passed'] ?? false,
      perQuestionMarks: Map<String, int>.from((data['perQuestionMarks'] as Map?)?.map((k, v) => MapEntry(k, (v as num).toInt())) ?? {}),
      perQuestionFeedback: Map<String, String>.from(data['perQuestionFeedback'] ?? {}),
      feedback: data['feedback'],
      gradedBy: data['gradedBy'],
      gradedAt: (data['gradedAt'] as Timestamp?)?.toDate(),
      isLate: data['isLate'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'courseId': courseId,
      'quizId': quizId,
      'attemptNumber': attemptNumber,
      'status': status.name,
      'startedAt': Timestamp.fromDate(startedAt),
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'deadlineAt': deadlineAt != null ? Timestamp.fromDate(deadlineAt!) : null,
      'timeTakenSeconds': timeTakenSeconds,
      'answers': answers,
      'optionOrder': optionOrder,
      'questionOrder': questionOrder,
      'autoScore': autoScore,
      'manualScore': manualScore,
      'totalScore': totalScore,
      'totalMarks': totalMarks,
      'percentage': percentage,
      'passed': passed,
      'perQuestionMarks': perQuestionMarks,
      'perQuestionFeedback': perQuestionFeedback,
      'feedback': feedback,
      'gradedBy': gradedBy,
      'gradedAt': gradedAt != null ? Timestamp.fromDate(gradedAt!) : null,
      'isLate': isLate,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class QuizExtensionRequestModel {
  final String id;
  final String studentId;
  final String studentName;
  final String courseId;
  final String quizId;
  final String quizTitle;
  final String reason;
  final DateTime requestedUntil;
  final ExtensionStatus status;
  final String? adminNote;
  final DateTime? approvedUntil;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  const QuizExtensionRequestModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.courseId,
    required this.quizId,
    required this.quizTitle,
    required this.reason,
    required this.requestedUntil,
    required this.status,
    this.adminNote,
    this.approvedUntil,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
  });

  factory QuizExtensionRequestModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return QuizExtensionRequestModel(
      id: snapshot.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      courseId: data['courseId'] ?? '',
      quizId: data['quizId'] ?? '',
      quizTitle: data['quizTitle'] ?? '',
      reason: data['reason'] ?? '',
      requestedUntil: (data['requestedUntil'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: ExtensionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ExtensionStatus.pending,
      ),
      adminNote: data['adminNote'],
      approvedUntil: (data['approvedUntil'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'],
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'quizId': quizId,
      'quizTitle': quizTitle,
      'reason': reason,
      'requestedUntil': Timestamp.fromDate(requestedUntil),
      'status': status.name,
      'adminNote': adminNote,
      'approvedUntil': approvedUntil != null ? Timestamp.fromDate(approvedUntil!) : null,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class QuizExtensionModel {
  final String id;
  final String studentId;
  final String quizId;
  final String courseId;
  final DateTime extendedDueAt;
  final String grantedBy;
  final DateTime grantedAt;

  const QuizExtensionModel({
    required this.id,
    required this.studentId,
    required this.quizId,
    required this.courseId,
    required this.extendedDueAt,
    required this.grantedBy,
    required this.grantedAt,
  });

  factory QuizExtensionModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return QuizExtensionModel(
      id: snapshot.id,
      studentId: data['studentId'] ?? '',
      quizId: data['quizId'] ?? '',
      courseId: data['courseId'] ?? '',
      extendedDueAt: (data['extendedDueAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      grantedBy: data['grantedBy'] ?? '',
      grantedAt: (data['grantedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'quizId': quizId,
      'courseId': courseId,
      'extendedDueAt': Timestamp.fromDate(extendedDueAt),
      'grantedBy': grantedBy,
      'grantedAt': Timestamp.fromDate(grantedAt),
    };
  }
}
