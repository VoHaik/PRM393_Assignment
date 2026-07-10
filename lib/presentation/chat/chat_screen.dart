import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:historytalk_flutter/core/theme/lucide_icons.dart';
import 'chat_bloc.dart';
import '../../domain/entities/chat.dart';
import '../../core/theme/app_theme.dart';
import '../../injection_container.dart';

class ChatScreen extends StatefulWidget {
  final String sessionId;
  final String characterName;
  final String? characterImageUrl;

  const ChatScreen({
    super.key,
    required this.sessionId,
    required this.characterName,
    this.characterImageUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    // Resolve global ChatBloc and request message load
    _chatBloc = sl<ChatBloc>()..add(FetchMessagesRequested(sessionId: widget.sessionId));
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onSend() {
    final text = _inputController.text.trim();
    if (text.isNotEmpty) {
      _chatBloc.add(
        SendMessageSubmitted(
          sessionId: widget.sessionId,
          content: text,
          messageType: ChatMessageType.text,
        ),
      );
      _inputController.clear();
      _scrollToBottom();
    }
  }

  void _toggleRecording(bool isRecording) {
    if (isRecording) {
      _chatBloc.add(StopVoiceRecordingRequested());
    } else {
      _chatBloc.add(StartVoiceRecordingRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final textMuted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return BlocProvider.value(
      value: _chatBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              if (widget.characterImageUrl != null && widget.characterImageUrl!.isNotEmpty) ...[
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.characterImageUrl!),
                  radius: 18,
                ),
                const SizedBox(width: 10),
              ],
              Text(
                widget.characterName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0.5,
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.phoneCall),
              onPressed: () {
                // Future extension: Full voice call mode
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Message List View
              Expanded(
                child: BlocConsumer<ChatBloc, ChatState>(
                  listener: (context, state) {
                    if (state.messages.isNotEmpty || state.streamingText != null) {
                      _scrollToBottom();
                    }
                    if (state.recordedText.isNotEmpty && !state.isRecording) {
                      // Append recorded STT words directly into input controller on stop
                      _inputController.text = state.recordedText;
                    }
                  },
                  builder: (context, state) {
                    if (state.isMessagesLoading && state.messages.isEmpty) {
                      return Center(child: CircularProgressIndicator(color: accentColor));
                    }

                    final showStreaming = state.streamingText != null && state.streamingText!.isNotEmpty;
                    final totalItemCount = state.messages.length + (showStreaming ? 1 : 0);

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16.0),
                      itemCount: totalItemCount,
                      itemBuilder: (context, index) {
                        if (index == state.messages.length && showStreaming) {
                          // Render incremental stream bubble
                          return _buildMessageBubble(
                            message: ChatMessage(
                              id: 'streaming',
                              sessionId: widget.sessionId,
                              senderType: SenderType.assistant,
                              content: state.streamingText!,
                              messageType: ChatMessageType.text,
                              createdAt: DateTime.now(),
                            ),
                            isSpeaking: false,
                            accentColor: accentColor,
                            surfaceColor: surfaceColor,
                          );
                        }

                        final msg = state.messages[index];
                        final isSpeaking = state.speakingMessageId == msg.id;

                        return _buildMessageBubble(
                          message: msg,
                          isSpeaking: isSpeaking,
                          accentColor: accentColor,
                          surfaceColor: surfaceColor,
                        );
                      },
                    );
                  },
                ),
              ),

              // STT Partial transcript banner
              BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state.isRecording && state.recordedText.isNotEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: accentColor.withOpacity(0.08),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.mic, size: 14, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.recordedText,
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Chat Input Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                child: BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    return Row(
                      children: [
                        // Speech Recording Mic Button
                        IconButton(
                          icon: Icon(
                            state.isRecording ? Icons.stop : LucideIcons.mic,
                            color: state.isRecording ? Colors.red : accentColor,
                          ),
                          onPressed: () => _toggleRecording(state.isRecording),
                        ),
                        
                        // Text input field
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: borderColor),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: TextField(
                              controller: _inputController,
                              maxLines: null,
                              decoration: InputDecoration(
                                hintText: state.isRecording ? 'Đang lắng nghe...' : 'Nhập tin nhắn...',
                                hintStyle: TextStyle(color: textMuted),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _onSend(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Send message button
                        IconButton(
                          icon: Icon(LucideIcons.send, color: accentColor),
                          onPressed: state.isSending ? null : _onSend,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble({
    required ChatMessage message,
    required bool isSpeaking,
    required Color accentColor,
    required Color surfaceColor,
  }) {
    final isUser = message.senderType == SenderType.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && widget.characterImageUrl != null) ...[
            CircleAvatar(
              backgroundImage: NetworkImage(widget.characterImageUrl!),
              radius: 14,
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isUser ? accentColor : surfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : null,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  if (!isUser && message.content.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    // TTS Reader action button
                    GestureDetector(
                      onTap: () {
                        if (isSpeaking) {
                          _chatBloc.add(StopVoiceRequested());
                        } else {
                          _chatBloc.add(PlayVoiceRequested(
                            messageId: message.id,
                            content: message.content,
                          ));
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSpeaking ? Icons.pause : LucideIcons.volume2,
                            size: 14,
                            color: accentColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isSpeaking ? 'Đang đọc...' : 'Nghe đọc',
                            style: TextStyle(fontSize: 10, color: accentColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
