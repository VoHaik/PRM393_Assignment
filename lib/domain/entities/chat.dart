import '../entities/character.dart';

enum ChatMessageType { text, voice }

enum SenderType { user, assistant }

class ChatMessage {
  final String id;
  final String sessionId;
  final SenderType senderType;
  final String content;
  final ChatMessageType messageType;
  final int? tokensUsed;
  final int? processingTimeMs;
  final String? audioUrl;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.senderType,
    required this.content,
    required this.messageType,
    this.tokensUsed,
    this.processingTimeMs,
    this.audioUrl,
    required this.createdAt,
  });
}

class ChatSession {
  final String id;
  final String characterId;
  final String contextId;
  final String userId;
  final String characterName;
  final String? characterAvatarUrl;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;
  final String? characterTitle;
  final String? contextTitle;
  final CharacterEra? era;
  final String? category;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ChatSession({
    required this.id,
    required this.characterId,
    required this.contextId,
    required this.userId,
    required this.characterName,
    this.characterAvatarUrl,
    this.lastMessageContent,
    this.lastMessageAt,
    this.characterTitle,
    this.contextTitle,
    this.era,
    this.category,
    required this.isDeleted,
    this.createdAt,
    this.updatedAt,
  });
}

class ChatHistoryGroup {
  final CharacterEra era;
  final List<ChatSession> sessions;

  const ChatHistoryGroup({
    required this.era,
    required this.sessions,
  });
}

class SessionMessagesResponse {
  final List<ChatMessage> messages;
  final List<String> suggestedQuestions;

  const SessionMessagesResponse({
    required this.messages,
    required this.suggestedQuestions,
  });
}

class SendMessageResponse {
  final ChatMessage userMessage;
  final ChatMessage? assistantMessage;
  final List<String> suggestedQuestions;

  const SendMessageResponse({
    required this.userMessage,
    this.assistantMessage,
    required this.suggestedQuestions,
  });
}
