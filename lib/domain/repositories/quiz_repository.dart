import '../entities/quiz.dart';

abstract class QuizRepository {
  Future<List<Quiz>> getQuizzes();
  Future<Quiz> getQuizById(String id);
  Future<QuizSession> startQuiz(String quizId);
  Future<QuizResult> submitQuiz({
    required String sessionId,
    required List<SubmitAnswerItem> answers,
  });
  Future<List<MyResult>> getHistory({int page = 0, int size = 10});
  Future<QuizResultDetail> getResultDetail(String sessionId);
}
