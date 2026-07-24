import 'package:dio/dio.dart';
import '../../domain/entities/historical_context.dart';
import '../../domain/repositories/historical_context_repository.dart';
import '../models/historical_context_model.dart';

class HistoricalContextRepositoryImpl implements HistoricalContextRepository {
  final Dio _dio;

  HistoricalContextRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<HistoricalContext>> getContexts() async {
    final response = await _dio.get('/historical-contexts');
    final apiResponse = response.data;
    
    // The API returns paginated data where the actual list is under 'content' key
    final List<dynamic> content = apiResponse['data'] != null && apiResponse['data']['content'] != null
        ? apiResponse['data']['content']
        : (apiResponse['data'] is List ? apiResponse['data'] : []);

    return content.map((item) => HistoricalContextModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<HistoricalContext> getContextById(String id) async {
    final response = await _dio.get('/historical-contexts/$id');
    final apiResponse = response.data;
    return HistoricalContextModel.fromJson(apiResponse['data']);
  }
}
