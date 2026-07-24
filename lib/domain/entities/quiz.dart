enum QuizLevel { easy, medium, hard }

enum QuizEra { all, ancient, medieval, modern, contemporary }

class QuizSummary {
  final String quizId;
  final String title;
  final QuizLevel level;
  final QuizEra era;
  final int playCount;
  final String? contextTitle;

  const QuizSummary({
    required this.quizId,
    required this.title,
    required this.level,
    required this.era,
    required this.playCount,
    this.contextTitle,
  });
}

class Quiz extends QuizSummary {
  final String? description;
  final int? durationSeconds;
  final double? rating;
  final int? grade;
  final int? chapterNumber;
  final String? chapterTitle;

  const Quiz({
    required super.quizId,
    required super.title,
    required super.level,
    required super.era,
    required super.playCount,
    super.contextTitle,
    this.description,
    this.durationSeconds,
    this.rating,
    this.grade,
    this.chapterNumber,
    this.chapterTitle,
  });
}

class QuizQuestion {
  final String questionId;
  final String content;
  final List<String> options;
  final int correctAnswer;
  final int orderIndex;
  final String? explanation;

  const QuizQuestion({
    required this.questionId,
    required this.content,
    required this.options,
    required this.correctAnswer,
    required this.orderIndex,
    this.explanation,
  });
}

class QuizSession {
  final String sessionId;
  final String quizId;
  final String title;
  final int limitedTime;
  final int durationSeconds;
  final List<QuizQuestion> questions;

  const QuizSession({
    required this.sessionId,
    required this.quizId,
    required this.title,
    required this.limitedTime,
    required this.durationSeconds,
    required this.questions,
  });
}

class SubmitAnswerItem {
  final String questionId;
  final int selectedAnswer;

  const SubmitAnswerItem({
    required this.questionId,
    required this.selectedAnswer,
  });
}

class SubmitAnswers {
  final String sessionId;
  final List<SubmitAnswerItem> answers;

  const SubmitAnswers({
    required this.sessionId,
    required this.answers,
  });
}

class QuizResult {
  final String resultId;
  final double score;
  final int totalQuestions;
  final double percentage;
  final DateTime startTime;
  final DateTime endTime;
  final List<int> correctAnswers;
  final List<int> wrongAnswers;

  const QuizResult({
    required this.resultId,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.startTime,
    required this.endTime,
    required this.correctAnswers,
    required this.wrongAnswers,
  });
}

class MyResult {
  final String sessionId;
  final String quizId;
  final String quizTitle;
  final double score;
  final int totalQuestions;
  final double percentage;
  final DateTime completedAt;

  const MyResult({
    required this.sessionId,
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.completedAt,
  });
}

class QuizResultDetailQuestion extends QuizQuestion {
  final int selectedAnswer;
  final bool correct;

  const QuizResultDetailQuestion({
    required super.questionId,
    required super.content,
    required super.options,
    required super.correctAnswer,
    required super.orderIndex,
    super.explanation,
    required this.selectedAnswer,
    required this.correct,
  });
}

class QuizResultDetail {
  final String sessionId;
  final String quizId;
  final String quizTitle;
  final double score;
  final int totalQuestions;
  final double percentage;
  final int limitedTime;
  final DateTime startedAt;
  final DateTime completedAt;
  final List<QuizResultDetailQuestion> questions;

  const QuizResultDetail({
    required this.sessionId,
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.limitedTime,
    required this.startedAt,
    required this.completedAt,
    required this.questions,
  });
}
