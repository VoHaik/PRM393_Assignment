import '../../domain/entities/quiz.dart';

QuizLevel parseQuizLevel(String? levelStr) {
  switch (levelStr?.toUpperCase()) {
    case 'EASY':
      return QuizLevel.easy;
    case 'MEDIUM':
      return QuizLevel.medium;
    case 'HARD':
    default:
      return QuizLevel.hard;
  }
}

String serializeQuizLevel(QuizLevel level) {
  switch (level) {
    case QuizLevel.easy:
      return 'EASY';
    case QuizLevel.medium:
      return 'MEDIUM';
    case QuizLevel.hard:
      return 'HARD';
  }
}

QuizEra parseQuizEra(String? eraStr) {
  switch (eraStr?.toUpperCase()) {
    case 'ALL':
      return QuizEra.all;
    case 'ANCIENT':
      return QuizEra.ancient;
    case 'MEDIEVAL':
      return QuizEra.medieval;
    case 'MODERN':
      return QuizEra.modern;
    case 'CONTEMPORARY':
    default:
      return QuizEra.contemporary;
  }
}

String serializeQuizEra(QuizEra era) {
  switch (era) {
    case QuizEra.all:
      return 'ALL';
    case QuizEra.ancient:
      return 'ANCIENT';
    case QuizEra.medieval:
      return 'MEDIEVAL';
    case QuizEra.modern:
      return 'MODERN';
    case QuizEra.contemporary:
      return 'CONTEMPORARY';
  }
}

class QuizSummaryModel extends QuizSummary {
  const QuizSummaryModel({
    required super.quizId,
    required super.title,
    required super.level,
    required super.era,
    required super.playCount,
    super.contextTitle,
  });

  factory QuizSummaryModel.fromJson(Map<String, dynamic> json) {
    return QuizSummaryModel(
      quizId: json['quizId'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      level: parseQuizLevel(json['level'] as String?),
      era: parseQuizEra(json['era'] as String?),
      playCount: json['playCount'] as int? ?? 0,
      contextTitle: json['contextTitle'] as String?,
    );
  }
}

class QuizModel extends Quiz {
  const QuizModel({
    required super.quizId,
    required super.title,
    required super.level,
    required super.era,
    required super.playCount,
    super.contextTitle,
    super.description,
    super.durationSeconds,
    super.rating,
    super.grade,
    super.chapterNumber,
    super.chapterTitle,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    return QuizModel(
      quizId: json['quizId'] as String? ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      level: parseQuizLevel(json['level'] as String?),
      era: parseQuizEra(json['era'] as String?),
      playCount: json['playCount'] as int? ?? 0,
      contextTitle: json['contextTitle'] as String?,
      description: json['description'] as String?,
      durationSeconds: json['durationSeconds'] as int?,
      rating: (json['rating'] as num?)?.toDouble(),
      grade: json['grade'] as int?,
      chapterNumber: json['chapterNumber'] as int?,
      chapterTitle: json['chapterTitle'] as String?,
    );
  }
}

class QuizQuestionModel extends QuizQuestion {
  const QuizQuestionModel({
    required super.questionId,
    required super.content,
    required super.options,
    required super.correctAnswer,
    required super.orderIndex,
    super.explanation,
  });

  factory QuizQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizQuestionModel(
      questionId: json['questionId'] as String? ?? json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] as int? ?? 0,
      orderIndex: json['orderIndex'] as int? ?? 0,
      explanation: json['explanation'] as String?,
    );
  }
}

class QuizSessionModel extends QuizSession {
  const QuizSessionModel({
    required super.sessionId,
    required super.quizId,
    required super.title,
    required super.limitedTime,
    required super.durationSeconds,
    required super.questions,
  });

  factory QuizSessionModel.fromJson(Map<String, dynamic> json) {
    final rawLimitedTime = json['limitedTime'] as int? ?? 0;
    final rawDuration = json['durationSeconds'] as int? ?? 0;
    // Fallback default: 15 minutes (900 seconds) if not provided by BE
    final effectiveTime = (rawLimitedTime > 0)
        ? rawLimitedTime
        : (rawDuration > 0 ? rawDuration : 900);

    return QuizSessionModel(
      sessionId: json['sessionId'] as String? ?? '',
      quizId: json['quizId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      limitedTime: effectiveTime,
      durationSeconds: effectiveTime,
      questions: json['questions'] != null
          ? (json['questions'] as List)
              .map((q) => QuizQuestionModel.fromJson(q as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class QuizResultModel extends QuizResult {
  const QuizResultModel({
    required super.resultId,
    required super.score,
    required super.totalQuestions,
    required super.percentage,
    required super.startTime,
    required super.endTime,
    required super.correctAnswers,
    required super.wrongAnswers,
  });

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic raw) {
      if (raw == null) return DateTime.now();
      try {
        return DateTime.parse(raw.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return QuizResultModel(
      resultId: json['resultId'] as String? ?? json['id'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      startTime: parseDate(json['startTime']),
      endTime: parseDate(json['endTime']),
      correctAnswers: List<int>.from(json['correctAnswers'] ?? []),
      wrongAnswers: List<int>.from(json['wrongAnswers'] ?? []),
    );
  }
}

class MyResultModel extends MyResult {
  const MyResultModel({
    required super.sessionId,
    required super.quizId,
    required super.quizTitle,
    required super.score,
    required super.totalQuestions,
    required super.percentage,
    required super.completedAt,
  });

  factory MyResultModel.fromJson(Map<String, dynamic> json) {
    DateTime parseCompletedAt(dynamic raw) {
      if (raw == null) return DateTime.now();
      try {
        return DateTime.parse(raw.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return MyResultModel(
      sessionId: json['sessionId'] as String? ?? '',
      quizId: json['quizId'] as String? ?? '',
      quizTitle: json['quizTitle'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      completedAt: parseCompletedAt(json['completedAt'] ?? json['completedTime']),
    );
  }
}

class QuizResultDetailQuestionModel extends QuizResultDetailQuestion {
  const QuizResultDetailQuestionModel({
    required super.questionId,
    required super.content,
    required super.options,
    required super.correctAnswer,
    required super.orderIndex,
    super.explanation,
    required super.selectedAnswer,
    required super.correct,
  });

  factory QuizResultDetailQuestionModel.fromJson(Map<String, dynamic> json) {
    return QuizResultDetailQuestionModel(
      questionId: json['questionId'] as String? ?? json['id'] as String? ?? '',
      content: json['content'] as String? ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correctAnswer'] as int? ?? 0,
      orderIndex: json['orderIndex'] as int? ?? 0,
      explanation: json['explanation'] as String?,
      selectedAnswer: json['selectedAnswer'] as int? ?? -1,
      correct: json['correct'] as bool? ?? false,
    );
  }
}

class QuizResultDetailModel extends QuizResultDetail {
  const QuizResultDetailModel({
    required super.sessionId,
    required super.quizId,
    required super.quizTitle,
    required super.score,
    required super.totalQuestions,
    required super.percentage,
    required super.limitedTime,
    required super.startedAt,
    required super.completedAt,
    required super.questions,
  });

  factory QuizResultDetailModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic raw) {
      if (raw == null) return DateTime.now();
      try {
        return DateTime.parse(raw.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return QuizResultDetailModel(
      sessionId: json['sessionId'] as String? ?? '',
      quizId: json['quizId'] as String? ?? '',
      quizTitle: json['quizTitle'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      limitedTime: json['limitedTime'] as int? ?? 0,
      startedAt: parseDate(json['startedAt'] ?? json['startTime']),
      completedAt: parseDate(json['completedAt'] ?? json['endTime']),
      questions: json['questions'] != null
          ? (json['questions'] as List)
              .map((q) => QuizResultDetailQuestionModel.fromJson(q as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
