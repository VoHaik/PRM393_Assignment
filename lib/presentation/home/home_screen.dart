import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:historytalk_flutter/core/theme/lucide_icons.dart';
import '../auth/auth_bloc.dart';
import '../characters/character_detail_screen.dart';
import '../widgets/character_card.dart';
import '../widgets/context_card.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/historical_context.dart';
import '../../domain/entities/chat.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/historical_context_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../../injection_container.dart';
import '../../core/theme/app_theme.dart';
import '../historical_context/historical_context_detail_screen.dart';
import '../chat/chat_screen.dart';
import '../quiz/quiz_result_screen.dart';
// Note: For 'View all' actions, you might want to push to corresponding screens.

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CharacterRepository _charRepository = sl<CharacterRepository>();
  final HistoricalContextRepository _ctxRepository = sl<HistoricalContextRepository>();
  final ChatRepository _chatRepository = sl<ChatRepository>();
  final QuizRepository _quizRepository = sl<QuizRepository>();

  List<Character> _featuredCharacters = [];
  List<HistoricalContext> _hotContexts = [];
  List<ChatSession> _recentChats = [];
  List<MyResult> _recentQuizzes = [];
  
  bool _isLoadingChars = true;
  bool _isLoadingCtx = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() {
      _isLoadingChars = true;
      _isLoadingCtx = true;
    });

    try {
      final futures = await Future.wait([
        _charRepository.getCharacters().catchError((_) => <Character>[]),
        _ctxRepository.getContexts().catchError((_) => <HistoricalContext>[]),
        _chatRepository.getHistory().catchError((_) => <ChatHistoryGroup>[]),
        _quizRepository.getHistory(page: 0, size: 3).catchError((_) => <MyResult>[]),
      ]);

      final chars = futures[0] as List<Character>;
      final contexts = futures[1] as List<HistoricalContext>;
      final historyGroups = futures[2] as List<ChatHistoryGroup>;
      final quizzes = futures[3] as List<MyResult>;

      // Flatten and sort chat sessions
      final allSessions = historyGroups.expand((g) => g.sessions).toList();
      allSessions.sort((a, b) {
        final t1 = a.lastMessageAt ?? a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final t2 = b.lastMessageAt ?? b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return t2.compareTo(t1);
      });

      setState(() {
        _featuredCharacters = chars.take(8).toList();
        _hotContexts = contexts.take(4).toList();
        _recentChats = allSessions.take(3).toList();
        _recentQuizzes = quizzes;
        _isLoadingChars = false;
        _isLoadingCtx = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingChars = false;
        _isLoadingCtx = false;
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  String _formatRelative(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return "Vừa xong";
    if (diff.inMinutes < 60) return "${diff.inMinutes} phút trước";
    if (diff.inHours < 24) return "${diff.inHours} giờ trước";
    if (diff.inDays < 7) return "${diff.inDays} ngày trước";
    return "${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final textMuted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadHomeData,
          color: accentColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ────────────────────────────────────────
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final userName = state is Authenticated ? state.user.userName : 'Bạn';
                    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.landmark, color: accentColor, size: 28),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_getGreeting(), style: TextStyle(fontSize: 11, color: textMuted)),
                                  Text(
                                    userName,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                            child: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // ── Hero Banner ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 3, color: accentColor),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Khám phá lịch sử qua từng nhân vật',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Trò chuyện và tìm hiểu về các sự kiện, nhân vật lịch sử nổi tiếng Việt Nam và thế giới.',
                                style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Bắt đầu ngay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      const SizedBox(width: 6),
                                      const Icon(LucideIcons.chevronRight, size: 14, color: Colors.white),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Featured Characters ───────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Nhân vật nổi bật',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Row(
                              children: [
                                Text('Xem tất cả', style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.bold)),
                                Icon(LucideIcons.chevronRight, size: 12, color: accentColor),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    _isLoadingChars
                        ? _buildFeaturedCharactersSkeletons()
                        : SizedBox(
                            height: 130,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              itemCount: _featuredCharacters.length,
                              itemBuilder: (context, index) {
                                final char = _featuredCharacters[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 10.0),
                                  child: CharacterCard(
                                    char: char,
                                    size: 'sm',
                                    onPress: () {
                                      Navigator.of(context).push(MaterialPageRoute(
                                        builder: (_) => CharacterDetailScreen(characterId: char.id),
                                      ));
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Recent Chats ───────────────────────────────────
                if (_recentChats.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Trò chuyện gần đây',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: Row(
                                children: [
                                  Text('Xem tất cả', style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.bold)),
                                  Icon(LucideIcons.chevronRight, size: 12, color: accentColor),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._recentChats.map((session) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    sessionId: session.id,
                                    characterName: session.characterName,
                                    characterImageUrl: session.characterAvatarUrl,
                                  )
                                ));
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: accentColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: session.characterAvatarUrl != null
                                        ? Image.network(session.characterAvatarUrl!, fit: BoxFit.cover)
                                        : Icon(LucideIcons.messageCircle, size: 16, color: accentColor),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            session.characterName,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          if (session.lastMessageContent != null)
                                            Text(
                                              session.lastMessageContent!,
                                              style: TextStyle(fontSize: 11, color: textMuted),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          else
                                            Text(
                                              'Bắt đầu trò chuyện ngay →',
                                              style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.bold),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (session.lastMessageAt != null || session.updatedAt != null)
                                      Text(
                                        _formatRelative(session.lastMessageAt ?? session.updatedAt!),
                                        style: TextStyle(fontSize: 10, color: textMuted),
                                      )
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                if (_recentChats.isNotEmpty) const SizedBox(height: 24),

                // ── Hot Contexts ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Bối cảnh lịch sử',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Row(
                              children: [
                                Text('Xem tất cả', style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.bold)),
                                Icon(LucideIcons.chevronRight, size: 12, color: accentColor),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      _isLoadingCtx
                          ? _buildContextSkeletons()
                          : Column(
                              children: _hotContexts.map((ctx) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ContextCard(
                                    ctx: ctx,
                                    variant: 'compact',
                                    onPress: () {
                                      Navigator.of(context).push(MaterialPageRoute(
                                        builder: (_) => HistoricalContextDetailScreen(context: ctx),
                                      ));
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Recent Quizzes ─────────────────────────────────
                if (_recentQuizzes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Kết quả quiz gần đây',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: Row(
                                children: [
                                  Text('Làm quiz mới', style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.bold)),
                                  Icon(LucideIcons.chevronRight, size: 12, color: accentColor),
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._recentQuizzes.map((result) {
                          final correctCount = ((result.percentage / 100) * result.totalQuestions).round();
                          final isLowScore = result.percentage < 50;
                          final scoreColor = result.percentage >= 70 ? const Color(0xFF22C55E) : (result.percentage >= 50 ? accentColor : const Color(0xFFEF4444));

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => QuizResultScreen(sessionId: result.sessionId),
                                ));
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: isLowScore ? const Color(0x33EF4444) : borderColor),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isLowScore ? const Color(0x14EF4444) : const Color(0x19EAB308),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(LucideIcons.trophy, size: 16, color: isLowScore ? const Color(0xFFEF4444) : const Color(0xFFEAB308)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            result.quizTitle,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              Text('Đúng $correctCount/${result.totalQuestions} câu', style: TextStyle(fontSize: 11, color: textMuted)),
                                              if (isLowScore) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0x1EEAB308),
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: const Color(0x4DEAB308)),
                                                  ),
                                                  child: const Text('Ôn tập ngay', style: TextStyle(color: Color(0xFFB45309), fontSize: 9, fontWeight: FontWeight.bold)),
                                                )
                                              ]
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text('${result.percentage.toStringAsFixed(0)}%', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: scoreColor)),
                                        Text('${result.completedAt.day.toString().padLeft(2,'0')}/${result.completedAt.month.toString().padLeft(2,'0')}', style: TextStyle(fontSize: 9, color: textMuted)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedCharactersSkeletons() {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        itemCount: 4,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: Container(
            width: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContextSkeletons() {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
