import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:historytalk_flutter/core/theme/lucide_icons.dart';
import '../auth/auth_bloc.dart';
import '../characters/character_detail_screen.dart';
import '../widgets/character_card.dart';
import '../widgets/context_card.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/historical_context.dart';
import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/historical_context_repository.dart';
import '../../injection_container.dart';
import '../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CharacterRepository _charRepository = sl<CharacterRepository>();
  final HistoricalContextRepository _ctxRepository = sl<HistoricalContextRepository>();

  List<Character> _featuredCharacters = [];
  List<HistoricalContext> _hotContexts = [];
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
      final chars = await _charRepository.getCharacters();
      final contexts = await _ctxRepository.getContexts();

      setState(() {
        _featuredCharacters = chars.take(8).toList();
        _hotContexts = contexts.take(4).toList();
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
                            decoration: BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
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
                            onTap: () {
                              // Action to view all characters/search
                            },
                            child: Row(
                              children: [
                                Text('Xem tất cả', style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.bold)),
                                Icon(LucideIcons.chevronRight, size: 14, color: accentColor),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
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
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => CharacterDetailScreen(characterId: char.id),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Hot Contexts ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sự kiện nổi bật',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                                      // Action to view context detail
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
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
              color: Colors.grey.shade200,
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
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
