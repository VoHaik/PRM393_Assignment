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

  void _onSend(ChatState state) {
    if (state.isSending) return;
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

  /// Splits assistant message content by '---' separator (same logic as web).
  List<String> _splitAssistantContent(String content) {
    return content
        .split(RegExp(r'\s*-{3,}\s*'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
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
            BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                return IconButton(
                  icon: Icon(
                    state.autoSpeak ? LucideIcons.volume2 : LucideIcons.volumeX,
                    color: state.autoSpeak ? accentColor : textMuted,
                  ),
                  tooltip: state.autoSpeak ? 'Tắt tự động đọc' : 'Bật tự động đọc',
                  onPressed: () {
                    _chatBloc.add(ToggleAutoSpeakRequested());
                  },
                );
              },
            ),
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

              // Suggested Questions
              BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state.suggestedQuestions.isNotEmpty && !state.isSending) {
                    return Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        border: Border(top: BorderSide(color: borderColor)),
                      ),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: state.suggestedQuestions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final question = state.suggestedQuestions[index];
                          return ActionChip(
                            label: Text(
                              question,
                              style: TextStyle(fontSize: 12, color: textMuted),
                            ),
                            backgroundColor: surfaceColor,
                            side: BorderSide(color: borderColor),
                            onPressed: () {
                              _chatBloc.add(
                                SendMessageSubmitted(
                                  sessionId: widget.sessionId,
                                  content: question,
                                  messageType: ChatMessageType.text,
                                ),
                              );
                              _scrollToBottom();
                            },
                          );
                        },
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
                    final isLocked = state.isSending || state.isRecording;
                    return Row(
                      children: [
                        // Speech Recording Mic Button
                        IconButton(
                          icon: Icon(
                            state.isRecording ? Icons.stop : LucideIcons.mic,
                            color: state.isRecording ? Colors.red : accentColor,
                          ),
                          onPressed: state.isSending
                              ? null
                              : () => _toggleRecording(state.isRecording),
                        ),

                        // Text input field
                        Expanded(
                          child: AnimatedOpacity(
                            opacity: state.isSending ? 0.5 : 1.0,
                            duration: const Duration(milliseconds: 200),
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
                                enabled: !isLocked,
                                decoration: InputDecoration(
                                  hintText: state.isSending
                                      ? 'Đang chờ phản hồi...'
                                      : state.isRecording
                                          ? 'Đang lắng nghe...'
                                          : 'Nhập tin nhắn...',
                                  hintStyle: TextStyle(color: textMuted),
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (_) => _onSend(state),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Send button — shows loading spinner while streaming
                        state.isSending
                            ? Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: Icon(LucideIcons.send, color: accentColor),
                                onPressed: () => _onSend(state),
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

    // User bubble: warm bronze/dark-teal to match web (distinct from assistant)
    final userBubbleColor = const Color(0xFF72383D); // same as lightAccent / web's --accent-bronze
    final userTextColor = Colors.white;
    // Assistant bubble: subtle elevated surface with border
    final assistantBubbleColor = surfaceColor;

    if (isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: userBubbleColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: userBubbleColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: userTextColor,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Assistant message: split by '---' into multiple bubbles (same as web)
    final parts = _splitAssistantContent(message.content);
    final displayParts = parts.isNotEmpty ? parts : [message.content];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.characterImageUrl != null && widget.characterImageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2.0, right: 8.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage(widget.characterImageUrl!),
                radius: 15,
              ),
            )
          else
            const SizedBox(width: 8),

          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Character name label
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                  child: Text(
                    widget.characterName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                // One bubble per split part
                ...displayParts.asMap().entries.map((entry) {
                  final partIndex = entry.key;
                  final part = entry.value;
                  final isLastPart = partIndex == displayParts.length - 1;

                  // Last part (or only part if not split): the question-back gets
                  // a slightly different style to signal it's a Socratic prompt
                  final isSocraticPart = displayParts.length > 1 && isLastPart;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                      decoration: BoxDecoration(
                        color: isSocraticPart
                            ? accentColor.withOpacity(0.12)
                            : assistantBubbleColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                        border: Border.all(
                          color: isSocraticPart
                              ? accentColor.withOpacity(0.4)
                              : accentColor.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isSocraticPart)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.help_outline_rounded,
                                      size: 11, color: accentColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Câu hỏi gợi mở',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: accentColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            part,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          // TTS button only on the last part
                          if (isLastPart && message.content.isNotEmpty) ...[
                            const SizedBox(height: 6),
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
                                    size: 13,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isSpeaking ? 'Đang đọc...' : 'Nghe đọc',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: accentColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
