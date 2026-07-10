import '../entities/chat.dart';

abstract class ChatRepository {
  Future<List<ChatHistoryGroup>> getHistory();
  
  Future<ChatSession> createSession({
    required String characterId,
    required String contextId,
  });

  Future<List<ChatMessage>> getMessages(String sessionId);

  Future<List<ChatMessage>> sendMessage({
    required String sessionId,
    required String content,
    required ChatMessageType messageType,
  });

  Stream<String> streamMessage({
    required String sessionId,
    required String content,
    required ChatMessageType messageType,
  });

  Future<List<ChatSession>> getSessions({
    String? characterId,
    String? contextId,
  });

  Future<void> deleteSession(String sessionId);
}
