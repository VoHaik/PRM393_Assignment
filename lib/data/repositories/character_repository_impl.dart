import 'package:dio/dio.dart';
import '../../domain/entities/character.dart';
import '../../domain/repositories/character_repository.dart';
import '../models/character_model.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  final Dio _dio;

  CharacterRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<Character>> getCharacters() async {
    final response = await _dio.get('/characters');
    final apiResponse = response.data;
    
    // Paginated list under data.content or data list directly
    final List<dynamic> content = apiResponse['data'] != null && apiResponse['data']['content'] != null
        ? apiResponse['data']['content']
        : (apiResponse['data'] is List ? apiResponse['data'] : []);

    return content.map((item) => CharacterModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<Character> getCharacterById(String id) async {
    final response = await _dio.get('/characters/$id');
    final apiResponse = response.data;
    return CharacterModel.fromJson(apiResponse['data']);
  }

  @override
  Future<List<Character>> getCharactersByContext(String contextId) async {
    final response = await _dio.get('/characters/context/$contextId');
    final apiResponse = response.data;
    final List<dynamic> list = apiResponse['data'] is List ? apiResponse['data'] : [];
    return list.map((item) => CharacterModel.fromJson(item as Map<String, dynamic>)).toList();
  }
}
