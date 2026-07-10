import '../../domain/entities/chat.dart';
import 'character_model.dart';

ChatMessageType parseChatMessageType(String? typeStr) {
  switch (typeStr?.toUpperCase()) {
    case 'VOICE':
      return ChatMessageType.voice;
    case 'TEXT':
    default:
      return ChatMessageType.text;
  }
}

String serializeChatMessageType(ChatMessageType type) {
  switch (type) {
    case ChatMessageType.voice:
      return 'VOICE';
    case ChatMessageType.text:
      return 'TEXT';
  }
}

SenderType parseSenderType(String? senderStr) {
  switch (senderStr?.toUpperCase()) {
    case 'ASSISTANT':
      return SenderType.assistant;
    case 'USER':
    default:
      return SenderType.user;
  }
}

String serializeSenderType(SenderType sender) {
  switch (sender) {
    case SenderType.assistant:
      return 'ASSISTANT';
    case SenderType.user:
      return 'USER';
  }
}

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.sessionId,
    required super.senderType,
    required super.content,
    required super.messageType,
    super.tokensUsed,
    super.processingTimeMs,
    super.audioUrl,
    required super.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      senderType: parseSenderType(json['senderType'] as String?),
      content: json['content'] as String? ?? '',
      messageType: parseChatMessageType(json['messageType'] as String?),
      tokensUsed: json['tokensUsed'] as int?,
      processingTimeMs: json['processingTimeMs'] as int?,
      audioUrl: json['audioUrl'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'senderType': serializeSenderType(senderType),
      'content': content,
      'messageType': serializeChatMessageType(messageType),
      'tokensUsed': tokensUsed,
      'processingTimeMs': processingTimeMs,
      'audioUrl': audioUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ChatSessionModel extends ChatSession {
  const ChatSessionModel({
    required super.id,
    required super.characterId,
    required super.contextId,
    required super.userId,
    required super.characterName,
    super.characterAvatarUrl,
    super.lastMessageContent,
    super.lastMessageAt,
    super.characterTitle,
    super.contextTitle,
    super.era,
    super.category,
    required super.isDeleted,
    super.createdAt,
    super.updatedAt,
  });

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      characterId: json['characterId'] as String? ?? '',
      contextId: json['contextId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      characterName: json['characterName'] as String? ?? '',
      characterAvatarUrl: json['characterAvatarUrl'] as String?,
      lastMessageContent: json['lastMessageContent'] as String?,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
      characterTitle: json['characterTitle'] as String?,
      contextTitle: json['contextTitle'] as String?,
      era: json['era'] != null ? parseCharacterEra(json['era'] as String) : null,
      category: json['category'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'characterId': characterId,
      'contextId': contextId,
      'userId': userId,
      'characterName': characterName,
      'characterAvatarUrl': characterAvatarUrl,
      'lastMessageContent': lastMessageContent,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'characterTitle': characterTitle,
      'contextTitle': contextTitle,
      'era': era != null ? serializeCharacterEra(era!) : null,
      'category': category,
      'isDeleted': isDeleted,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

class ChatHistoryGroupModel extends ChatHistoryGroup {
  const ChatHistoryGroupModel({
    required super.era,
    required super.sessions,
  });

  factory ChatHistoryGroupModel.fromJson(Map<String, dynamic> json) {
    return ChatHistoryGroupModel(
      era: parseCharacterEra(json['era'] as String?),
      sessions: json['sessions'] != null
          ? (json['sessions'] as List)
              .map((s) => ChatSessionModel.fromJson(s as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
