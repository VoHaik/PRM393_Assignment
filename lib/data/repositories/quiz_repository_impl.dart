import 'package:dio/dio.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../models/quiz_model.dart';

class QuizRepositoryImpl implements QuizRepository {
  final Dio _dio;

  QuizRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<Quiz>> getQuizzes() async {
    final response = await _dio.get('/quizzes');
    final apiResponse = response.data;
    final List<dynamic> list = apiResponse['data'] is List ? apiResponse['data'] : [];
    return list.map((item) => QuizModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<Quiz> getQuizById(String id) async {
    final response = await _dio.get('/quizzes/$id');
    final apiResponse = response.data;
    return QuizModel.fromJson(apiResponse['data']);
  }

  @override
  Future<QuizSession> startQuiz(String quizId) async {
    final response = await _dio.post(
      '/quizzes/$quizId/start',
      data: {},
    );
    final apiResponse = response.data;
    final session = QuizSessionModel.fromJson(apiResponse['data']);
    
    // Sort questions by orderIndex
    session.questions.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return session;
  }

  @override
  Future<QuizResult> submitQuiz({
    required String sessionId,
    required List<SubmitAnswerItem> answers,
  }) async {
    final response = await _dio.post(
      '/quizzes/submit',
      data: {
        'sessionId': sessionId,
        'answers': answers.map((a) => {
          'questionId': a.questionId,
          'selectedAnswer': a.selectedAnswer,
        }).toList(),
      },
    );
    final apiResponse = response.data;
    return QuizResultModel.fromJson(apiResponse['data']);
  }

  @override
  Future<List<MyResult>> getHistory({int page = 0, int size = 10}) async {
    final response = await _dio.get(
      '/quizzes/results/me',
      queryParameters: {'page': page, 'size': size},
    );
    final apiResponse = response.data;
    final content = apiResponse['data'] != null && apiResponse['data']['content'] != null
        ? apiResponse['data']['content'] as List
        : [];
    return content.map((item) => MyResultModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<QuizResultDetail> getResultDetail(String sessionId) async {
    final response = await _dio.get('/quizzes/results/me/$sessionId');
    final apiResponse = response.data;
    return QuizResultDetailModel.fromJson(apiResponse['data']);
  }
}
