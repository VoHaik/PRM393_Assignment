import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';
import '../models/chat_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final Dio _dio;

  ChatRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<ChatHistoryGroup>> getHistory() async {
    final response = await _dio.get('/chat/history');
    final apiResponse = response.data;
    final List<dynamic> list = apiResponse['data'] is List ? apiResponse['data'] : [];
    return list.map((item) => ChatHistoryGroupModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<ChatSession> createSession({
    required String characterId,
    required String contextId,
  }) async {
    final response = await _dio.post(
      '/chat/sessions',
      data: {'characterId': characterId, 'contextId': contextId},
    );
    final apiResponse = response.data;
    return ChatSessionModel.fromJson(apiResponse['data']);
  }

  @override
  Future<SessionMessagesResponse> getMessages(String sessionId) async {
    final response = await _dio.get('/chat/sessions/$sessionId/messages');
    final apiResponse = response.data;
    final data = apiResponse['data'];

    List<ChatMessage> messages = [];
    List<String> suggestedQuestions = [];

    if (data != null) {
      if (data is List) {
        messages = data.map((item) => ChatMessageModel.fromJson(item as Map<String, dynamic>)).toList();
      } else if (data is Map) {
        final msgs = data['messages'];
        if (msgs is List) {
          messages = msgs.map((item) => ChatMessageModel.fromJson(item as Map<String, dynamic>)).toList();
        }
        final sq = data['suggestedQuestions'];
        if (sq is List) {
          suggestedQuestions = sq.map((e) => e.toString()).toList();
        }
      }
    }

    return SessionMessagesResponse(messages: messages, suggestedQuestions: suggestedQuestions);
  }

  @override
  Future<SendMessageResponse> sendMessage({
    required String sessionId,
    required String content,
    required ChatMessageType messageType,
  }) async {
    final response = await _dio.post(
      '/chat/messages',
      data: {
        'sessionId': sessionId,
        'content': content,
        'messageType': serializeChatMessageType(messageType),
      },
    );

    final apiResponse = response.data;
    final data = apiResponse['data'];

    ChatMessage userMessage;
    ChatMessage? assistantMessage;
    List<String> suggestedQuestions = [];

    if (data['userMessage'] != null) {
      userMessage = ChatMessageModel.fromJson(data['userMessage']);
    } else if (data['message'] != null) {
      userMessage = ChatMessageModel.fromJson(data['message']);
    } else {
      throw Exception("Missing user message in response");
    }

    if (data['assistantMessage'] != null) {
      assistantMessage = ChatMessageModel.fromJson(data['assistantMessage']);
    }

    if (data['suggestedQuestions'] is List) {
      suggestedQuestions = (data['suggestedQuestions'] as List).map((e) => e.toString()).toList();
    }

    return SendMessageResponse(
      userMessage: userMessage,
      assistantMessage: assistantMessage,
      suggestedQuestions: suggestedQuestions,
    );
  }

  @override
  Stream<String> streamMessage({
    required String sessionId,
    required String content,
    required ChatMessageType messageType,
  }) async* {
    final response = await _dio.post(
      '/chat/messages/stream',
      data: {
        'sessionId': sessionId,
        'content': content,
        'messageType': serializeChatMessageType(messageType),
      },
      options: Options(
        responseType: ResponseType.stream,
        headers: {'Accept': 'text/event-stream'},
      ),
    );

    final Stream<Uint8List> byteStream = (response.data as ResponseBody).stream;
    
    // Buffer for assembling incomplete chunks
    String buffered = '';

    await for (final chunk in byteStream.cast<List<int>>().transform(utf8.decoder)) {
      buffered += chunk;
      
      // SSE events are separated by double-newlines
      final parts = buffered.split(RegExp(r'\n\n+'));
      
      // The last part might be incomplete, keep it in the buffer
      buffered = parts.removeLast();

      for (final event in parts) {
        final token = _parseSseEvent(event);
        if (token != null && token.isNotEmpty) {
          yield token;
        }
      }
    }

    // Process any remaining text in the buffer
    if (buffered.isNotEmpty) {
      final token = _parseSseEvent(buffered);
      if (token != null && token.isNotEmpty) {
        yield token;
      }
    }
  }

  String? _parseSseEvent(String event) {
    final lines = event.split('\n');
    for (final line in lines) {
      if (line.startsWith('data:')) {
        final dataStr = line.replaceFirst('data:', '').trim();
        if (dataStr == '[DONE]') return null;

        try {
          final Map<String, dynamic> parsed = jsonDecode(dataStr);
          if (parsed['success'] == false) {
            throw Exception(parsed['message'] ?? 'Yêu cầu stream thất bại');
          }

          if (parsed['content'] is String) return parsed['content'] as String;
          if (parsed['token'] is String) return parsed['token'] as String;
          if (parsed['delta'] is String) return parsed['delta'] as String;
          if (parsed['text'] is String) return parsed['text'] as String;
          
          final assistantMessage = parsed['assistantMessage'];
          if (assistantMessage is Map && assistantMessage['content'] is String) {
            return assistantMessage['content'] as String;
          }

          final choices = parsed['choices'];
          if (choices is List && choices.isNotEmpty) {
            final firstChoice = choices[0];
            if (firstChoice is Map) {
              final delta = firstChoice['delta'];
              if (delta is Map && delta['content'] is String) {
                return delta['content'] as String;
              }
              if (firstChoice['text'] is String) {
                return firstChoice['text'] as String;
              }
            }
          }
        } catch (_) {
          // If it is raw plain text or invalid JSON, return it directly if not [DONE]
          if (dataStr.isNotEmpty && dataStr != '[DONE]') {
            return dataStr;
          }
        }
      }
    }
    return null;
  }

  @override
  Future<List<ChatSession>> getSessions({
    String? characterId,
    String? contextId,
  }) async {
    // Backend requires BOTH characterId and contextId as mandatory @RequestParam.
    // Calling without them results in a 400 Bad Request.
    if (characterId == null || characterId.isEmpty ||
        contextId == null || contextId.isEmpty) {
      return []; // Return empty list rather than making an invalid API call
    }

    final response = await _dio.get(
      '/chat/sessions',
      queryParameters: {
        'characterId': characterId,
        'contextId': contextId,
      },
    );
    final apiResponse = response.data;
    final List<dynamic> list = apiResponse['data'] is List ? apiResponse['data'] : [];
    return list.map((item) => ChatSessionModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await _dio.patch('/chat/sessions/$sessionId/soft-delete');
  }
}
