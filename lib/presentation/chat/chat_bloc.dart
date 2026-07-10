import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../core/utils/azure_tts_client.dart';
import '../../core/utils/speech_to_text_service.dart';

// --- EVENTS ---
abstract class ChatEvent {}

class FetchSessionsRequested extends ChatEvent {
  final String? characterId;
  final String? contextId;
  FetchSessionsRequested({this.characterId, this.contextId});
}

class CreateSessionRequested extends ChatEvent {
  final String characterId;
  final String contextId;
  CreateSessionRequested({required this.characterId, required this.contextId});
}

class FetchMessagesRequested extends ChatEvent {
  final String sessionId;
  FetchMessagesRequested({required this.sessionId});
}

class SendMessageSubmitted extends ChatEvent {
  final String sessionId;
  final String content;
  final ChatMessageType messageType;
  SendMessageSubmitted({
    required this.sessionId,
    required this.content,
    required this.messageType,
  });
}

class DeleteSessionRequested extends ChatEvent {
  final String sessionId;
  DeleteSessionRequested({required this.sessionId});
}

class PlayVoiceRequested extends ChatEvent {
  final String messageId;
  final String content;
  PlayVoiceRequested({required this.messageId, required this.content});
}

class StopVoiceRequested extends ChatEvent {}

class StartVoiceRecordingRequested extends ChatEvent {}

class StopVoiceRecordingRequested extends ChatEvent {}

class SpeechWordsChanged extends ChatEvent {
  final String words;
  final bool isFinal;
  SpeechWordsChanged({required this.words, required this.isFinal});
}

// --- STATE ---
class ChatState {
  final List<ChatSession> sessions;
  final List<ChatMessage> messages;
  final bool isSessionsLoading;
  final bool isMessagesLoading;
  final bool isSending;
  final String? streamingText;
  final String? speakingMessageId;
  final bool isRecording;
  final String recordedText;
  final String? error;

  ChatState({
    this.sessions = const [],
    this.messages = const [],
    this.isSessionsLoading = false,
    this.isMessagesLoading = false,
    this.isSending = false,
    this.streamingText,
    this.speakingMessageId,
    this.isRecording = false,
    this.recordedText = '',
    this.error,
  });

  ChatState copyWith({
    List<ChatSession>? sessions,
    List<ChatMessage>? messages,
    bool? isSessionsLoading,
    bool? isMessagesLoading,
    bool? isSending,
    String? streamingText,
    String? speakingMessageId,
    bool? isRecording,
    String? recordedText,
    String? error,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      messages: messages ?? this.messages,
      isSessionsLoading: isSessionsLoading ?? this.isSessionsLoading,
      isMessagesLoading: isMessagesLoading ?? this.isMessagesLoading,
      isSending: isSending ?? this.isSending,
      streamingText: streamingText, // Allows setting to null
      speakingMessageId: speakingMessageId ?? this.speakingMessageId,
      isRecording: isRecording ?? this.isRecording,
      recordedText: recordedText ?? this.recordedText,
      error: error,
    );
  }
}

// --- BLOC ---
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  final AzureTtsClient _azureTtsClient;
  final SpeechToTextService _speechToTextService;

  ChatBloc({
    required ChatRepository chatRepository,
    required AzureTtsClient azureTtsClient,
    required SpeechToTextService speechToTextService,
  })  : _chatRepository = chatRepository,
        _azureTtsClient = azureTtsClient,
        _speechToTextService = speechToTextService,
        super(ChatState()) {
    on<FetchSessionsRequested>(_onFetchSessionsRequested);
    on<CreateSessionRequested>(_onCreateSessionRequested);
    on<FetchMessagesRequested>(_onFetchMessagesRequested);
    on<SendMessageSubmitted>(_onSendMessageSubmitted);
    on<DeleteSessionRequested>(_onDeleteSessionRequested);
    on<PlayVoiceRequested>(_onPlayVoiceRequested);
    on<StopVoiceRequested>(_onStopVoiceRequested);
    on<StartVoiceRecordingRequested>(_onStartVoiceRecordingRequested);
    on<StopVoiceRecordingRequested>(_onStopVoiceRecordingRequested);
    on<SpeechWordsChanged>(_onSpeechWordsChanged);
  }

  Future<void> _onFetchSessionsRequested(
      FetchSessionsRequested event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isSessionsLoading: true));
    try {
      final sessions = await _chatRepository.getSessions(
        characterId: event.characterId,
        contextId: event.contextId,
      );
      emit(state.copyWith(sessions: sessions, isSessionsLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isSessionsLoading: false));
    }
  }

  Future<void> _onCreateSessionRequested(
      CreateSessionRequested event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isMessagesLoading: true));
    try {
      final newSession = await _chatRepository.createSession(
        characterId: event.characterId,
        contextId: event.contextId,
      );
      final updatedSessions = List<ChatSession>.from(state.sessions)..insert(0, newSession);
      emit(state.copyWith(
        sessions: updatedSessions,
        messages: [],
        isMessagesLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isMessagesLoading: false));
    }
  }

  Future<void> _onFetchMessagesRequested(
      FetchMessagesRequested event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isMessagesLoading: true));
    try {
      final messages = await _chatRepository.getMessages(event.sessionId);
      emit(state.copyWith(messages: messages, isMessagesLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isMessagesLoading: false));
    }
  }

  Future<void> _onSendMessageSubmitted(
      SendMessageSubmitted event, Emitter<ChatState> emit) async {
    // 1. Add user message locally
    final userMsg = ChatMessage(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      sessionId: event.sessionId,
      senderType: SenderType.user,
      content: event.content,
      messageType: event.messageType,
      createdAt: DateTime.now(),
    );
    final updatedMessages = List<ChatMessage>.from(state.messages)..add(userMsg);
    emit(state.copyWith(messages: updatedMessages, isSending: true, streamingText: ''));

    try {
      // 2. Stream assistant reply via SSE
      String fullContent = '';
      await emit.forEach<String>(
        _chatRepository.streamMessage(
          sessionId: event.sessionId,
          content: event.content,
          messageType: event.messageType,
        ),
        onData: (token) {
          fullContent += token;
          return state.copyWith(streamingText: fullContent);
        },
        onError: (err, stack) {
          return state.copyWith(error: err.toString(), isSending: false);
        },
      );

      // 3. Once stream is complete, reload all messages from server to get token count and proper message IDs
      final freshMessages = await _chatRepository.getMessages(event.sessionId);
      emit(state.copyWith(messages: freshMessages, isSending: false, streamingText: null));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isSending: false, streamingText: null));
    }
  }

  Future<void> _onDeleteSessionRequested(
      DeleteSessionRequested event, Emitter<ChatState> emit) async {
    try {
      await _chatRepository.deleteSession(event.sessionId);
      final updatedSessions = state.sessions.where((s) => s.id != event.sessionId).toList();
      emit(state.copyWith(sessions: updatedSessions));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onPlayVoiceRequested(PlayVoiceRequested event, Emitter<ChatState> emit) async {
    emit(state.copyWith(speakingMessageId: event.messageId));
    try {
      final player = await _azureTtsClient.speak(event.content);
      
      // Listen for player completion to clear speaking state
      player.onPlayerComplete.listen((_) {
        add(StopVoiceRequested());
      });
    } catch (e) {
      emit(state.copyWith(error: e.toString(), speakingMessageId: null));
    }
  }

  Future<void> _onStopVoiceRequested(StopVoiceRequested event, Emitter<ChatState> emit) async {
    await _azureTtsClient.stop();
    emit(state.copyWith(speakingMessageId: null));
  }

  Future<void> _onStartVoiceRecordingRequested(
      StartVoiceRecordingRequested event, Emitter<ChatState> emit) async {
    try {
      final initialized = await _speechToTextService.initialize();
      if (initialized) {
        emit(state.copyWith(isRecording: true, recordedText: ''));
        await _speechToTextService.startListening(
          onResult: (words, isFinal) {
            add(SpeechWordsChanged(words: words, isFinal: isFinal));
          },
        );
      } else {
        emit(state.copyWith(error: 'Quyền truy cập micro bị từ chối.'));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isRecording: false));
    }
  }

  Future<void> _onStopVoiceRecordingRequested(
      StopVoiceRecordingRequested event, Emitter<ChatState> emit) async {
    await _speechToTextService.stopListening();
    emit(state.copyWith(isRecording: false));
  }

  void _onSpeechWordsChanged(SpeechWordsChanged event, Emitter<ChatState> emit) {
    emit(state.copyWith(
      recordedText: event.words,
      isRecording: !event.isFinal, // Stop recording state if it's final
    ));
  }

  @override
  Future<void> close() {
    _azureTtsClient.dispose();
    _speechToTextService.stopListening();
    return super.close();
  }
}
