import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:historytalk_flutter/core/theme/lucide_icons.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/character_repository.dart';
import '../../domain/repositories/chat_repository.dart';
import '../chat/chat_bloc.dart';
import '../widgets/context_card.dart';
import '../../injection_container.dart';
import '../../core/theme/app_theme.dart';

const Map<CharacterEra, Color> eraHeroBgs = {
  CharacterEra.ancient: Color(0xFF2C1810),
  CharacterEra.medieval: Color(0xFF1A0E38),
  CharacterEra.modern: Color(0xFF0A2420),
  CharacterEra.contemporary: Color(0xFF0D1B2A),
};

class CharacterDetailScreen extends StatefulWidget {
  final String characterId;

  const CharacterDetailScreen({super.key, required this.characterId});

  @override
  State<CharacterDetailScreen> createState() => _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends State<CharacterDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CharacterRepository _charRepository = sl<CharacterRepository>();
  final ChatRepository _chatRepository = sl<ChatRepository>();

  Character? _character;
  List<ChatSession> _sessions = [];
  bool _isLoadingChar = true;
  bool _isLoadingSessions = true;
  bool _isCreatingSession = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCharacterData();
    _loadSessions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCharacterData() async {
    try {
      final char = await _charRepository.getCharacterById(widget.characterId);
      setState(() {
        _character = char;
        _isLoadingChar = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingChar = false;
      });
    }
  }

  Future<void> _loadSessions() async {
    try {
      final sessions = await _chatRepository.getSessions(characterId: widget.characterId);
      setState(() {
        _sessions = sessions;
        _isLoadingSessions = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingSessions = false;
      });
    }
  }

  String _formatDateRange(Character char) {
    String formatDate(int? y, int? m, int? d, bool? bc) {
      if (y == null) return '';
      final parts = <String>[];
      if (d != null) parts.add(d.toString().padLeft(2, '0'));
      if (m != null) parts.add(m.toString().padLeft(2, '0'));
      parts.add(y.toString());
      return parts.join('/') + (bc == true ? ' TCN' : '');
    }

    final born = formatDate(char.bornYear, char.bornMonth, char.bornDay, char.isBornBc);
    final death = formatDate(char.deathYear, char.deathMonth, char.deathDay, char.isDeathBc);
    return [born, death].where((s) => s.isNotEmpty).join('  –  ');
  }

  void _onDeleteSession(String sessionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa cuộc trò chuyện?'),
        content: const Text('Cuộc trò chuyện này sẽ bị xóa vĩnh viễn và không thể khôi phục lại.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoadingSessions = true;
      });
      try {
        await _chatRepository.deleteSession(sessionId);
        _loadSessions();
      } catch (e) {
        setState(() {
          _isLoadingSessions = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xóa cuộc trò chuyện: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _startChat() async {
    if (_character == null || _character!.contexts == null || _character!.contexts!.isEmpty) return;
    
    final contextId = _character!.contexts!.first.id;
    final contextName = _character!.contexts!.first.name;

    setState(() {
      _isCreatingSession = true;
    });

    try {
      // Look for existing session
      final existing = _sessions.firstWhere(
        (s) => s.contextId == contextId,
        orElse: () => const ChatSession(
          id: '',
          characterId: '',
          contextId: '',
          userId: '',
          characterName: '',
          isDeleted: false,
          createdAt: null,
          updatedAt: null,
        ),
      );

      String sessionId = existing.id;
      if (sessionId.isEmpty) {
        final session = await _chatRepository.createSession(
          characterId: widget.characterId,
          contextId: contextId,
        );
        sessionId = session.id;
      }

      setState(() {
        _isCreatingSession = false;
      });

      // Navigate to chat room screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text('Trò chuyện với ${_character!.name}')),
            body: Center(child: Text('Trò chuyện session: $sessionId')),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isCreatingSession = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể bắt đầu cuộc trò chuyện: $e'), backgroundColor: Colors.red),
      );
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

    if (_isLoadingChar) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: accentColor)),
      );
    }

    if (_character == null) {
      return Scaffold(
        appBar: AppBar(elevation: 0, backgroundColor: Colors.transparent),
        body: const Center(child: Text('Không tìm thấy nhân vật')),
      );
    }

    final et = eraThemes[_character!.era] ?? eraThemes[CharacterEra.ancient]!;
    final heroBg = eraHeroBgs[_character!.era] ?? Colors.grey.shade900;
    final imageUri = _character!.imageUrl ?? _character!.image;
    final dates = _formatDateRange(_character!);

    return Scaffold(
      body: Stack(
        children: [
          // Scrollable Info Area
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Poster Image
                  Container(
                    height: 360,
                    color: heroBg,
                    child: imageUri != null && imageUri.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUri,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Text(
                              _character!.name[0].toUpperCase(),
                              style: TextStyle(
                                fontSize: 130,
                                fontWeight: FontWeight.w900,
                                color: et.glow.withOpacity(0.24),
                              ),
                            ),
                          ),
                  ),

                  // Name and detail headers
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: Column(
                      children: [
                        Text(
                          _character!.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        if (_character!.title != null && _character!.title!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            _character!.title!,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: accentColor, fontWeight: FontWeight.w600),
                          ),
                        ],
                        if (dates.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            dates,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: accentColor),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Custom Tab controller
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: textMuted,
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        tabs: const [
                          Tab(text: 'Thông tin'),
                          Tab(text: 'Trò chuyện'),
                        ],
                      ),
                    ),
                  ),

                  // Tab Views
                  SizedBox(
                    height: 400, // Fixed height container for tabs content
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInfoTab(textMuted, accentColor, borderColor),
                        _buildChatTab(accentColor, borderColor, textMuted),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Icon(LucideIcons.arrowLeft, color: Color(0xFF1C1917), size: 20),
              ),
            ),
          ),

          // Fixed Bottom CTA Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: ElevatedButton(
                onPressed: _isCreatingSession ? null : _startChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  minimumSize: const Size.fromHeight(54),
                ),
                child: _isCreatingSession
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.messageCircle, size: 20),
                          const SizedBox(width: 8),
                          Text('Chat với ${_character!.name}'),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(Color textMuted, Color accentColor, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Associated Contexts list
          if (_character!.contexts != null && _character!.contexts!.isNotEmpty) ...[
            Column(
              children: _character!.contexts!.map((ctx) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accentColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            ctx.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Icon(LucideIcons.chevronRight, size: 18, color: accentColor),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
          ],

          if (_character!.background != null && _character!.background!.isNotEmpty) ...[
            Text(
              _character!.background!,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 16),
          ],

          if (_character!.personality != null && _character!.personality!.isNotEmpty) ...[
            Text(
              _character!.personality!,
              style: const TextStyle(fontSize: 15, height: 1.6),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatTab(Color accentColor, Color borderColor, Color textMuted) {
    if (_isLoadingSessions) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    if (_sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Chưa có cuộc trò chuyện',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Nhấn "Chat với ${_character!.name}" để bắt đầu đối thoại!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final title = session.contextTitle ?? 'Cuộc trò chuyện';
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: Container(
            padding: const EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      if (session.lastMessageContent != null)
                        Text(
                          session.lastMessageContent!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: textMuted, height: 1.3),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 18),
                  onPressed: () => _onDeleteSession(session.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
