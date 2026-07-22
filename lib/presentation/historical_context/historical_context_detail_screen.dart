import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/historical_context.dart';
import '../../domain/repositories/historical_context_repository.dart';
import '../../injection_container.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/lucide_icons.dart';
import '../widgets/context_card.dart';
import '../widgets/in_app_video_player.dart';
import '../characters/character_detail_screen.dart';

class HistoricalContextDetailScreen extends StatefulWidget {
  /// Pass either [contextId] to load from API, or [context] if already loaded.
  final String? contextId;
  final HistoricalContext? context;

  const HistoricalContextDetailScreen({
    super.key,
    this.contextId,
    this.context,
  }) : assert(contextId != null || context != null,
            'Either contextId or context must be provided');

  @override
  State<HistoricalContextDetailScreen> createState() =>
      _HistoricalContextDetailScreenState();
}

class _HistoricalContextDetailScreenState
    extends State<HistoricalContextDetailScreen> {
  final HistoricalContextRepository _repo =
      sl<HistoricalContextRepository>();

  HistoricalContext? _ctx;
  bool _isLoading = true;
  String? _error;
  bool _showInlineVideo = false;

  @override
  void initState() {
    super.initState();
    if (widget.context != null) {
      _ctx = widget.context;
      _isLoading = false;
    } else {
      _loadContext();
    }
  }

  Future<void> _loadContext() async {
    try {
      final ctx = await _repo.getContextById(widget.contextId!);
      setState(() {
        _ctx = ctx;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _openExternalVideo(String url) async {
    final uri = Uri.parse(url.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _playVideoFullscreen(String url, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullscreenVideoModal(
          videoUrl: url,
          title: title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor =
        isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final textMuted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(child: CircularProgressIndicator(color: accentColor)),
      );
    }

    if (_error != null || _ctx == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text('Không thể tải sự kiện'),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: textMuted, fontSize: 12)),
              ],
            ],
          ),
        ),
      );
    }

    final ctx = _ctx!;
    final et = eraThemes[ctx.era] ?? eraThemes[eraThemes.keys.first]!;
    final yearTxt = formatContextYear(ctx);
    final hasVideo = ctx.videoUrl != null && ctx.videoUrl!.trim().isNotEmpty;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero Image App Bar ────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: et.cardBg,
            leading: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.arrowLeft,
                    color: Colors.white, size: 20),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: ctx.image != null && ctx.image!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: ctx.image!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        color: et.cardBg,
                        child: Center(
                          child: Text(
                            ctx.name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.w900,
                              color: et.glow.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: et.cardBg,
                      child: Center(
                        child: Text(
                          ctx.name[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.w900,
                            color: et.glow.withOpacity(0.3),
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          // ── Main Content Body ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Era + Category Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: et.bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          et.label,
                          style: TextStyle(
                            color: et.text,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (ctx.category != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (categoryColors[ctx.category] ??
                                    Colors.grey)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            categoryLabels[ctx.category] ?? '',
                            style: TextStyle(
                              color: categoryColors[ctx.category] ??
                                  Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Name
                  Text(
                    ctx.name,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold, height: 1.2),
                  ),

                  // Year & Location
                  if (yearTxt.isNotEmpty ||
                      (ctx.location != null &&
                          ctx.location!.isNotEmpty)) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (ctx.location != null &&
                            ctx.location!.isNotEmpty) ...[
                          Icon(LucideIcons.mapPin,
                              size: 14, color: textMuted),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            [yearTxt, ctx.location]
                                .where((s) =>
                                    s != null && s.isNotEmpty)
                                .join(' · '),
                            style: TextStyle(
                                fontSize: 13,
                                color: textMuted,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // In-App Video Player Section
                  if (hasVideo) ...[
                    _buildVideoSection(ctx, accentColor),
                    const SizedBox(height: 24),
                  ],

                  // Description
                  if (ctx.description != null &&
                      ctx.description!.isNotEmpty) ...[
                    Text(
                      ctx.description!,
                      style: const TextStyle(fontSize: 15, height: 1.7),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Related Characters Section
                  if (ctx.characterIds.isNotEmpty) ...[
                    Divider(color: borderColor),
                    const SizedBox(height: 12),
                    _buildRelatedCharactersSection(ctx, textMuted),
                    const SizedBox(height: 16),
                  ],

                  // Extra Info
                  if (ctx.period != null && ctx.period!.isNotEmpty) ...[
                    Divider(color: borderColor),
                    const SizedBox(height: 12),
                    _InfoRow(
                        icon: LucideIcons.clock,
                        label: 'Giai đoạn lịch sử',
                        value: ctx.period!,
                        textMuted: textMuted),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection(HistoricalContext ctx, Color accentColor) {
    final videoUrl = ctx.videoUrl!.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.film, size: 18, color: Colors.amber),
            SizedBox(width: 8),
            Text(
              'Video Tư liệu Lịch sử',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_showInlineVideo) ...[
          InAppVideoPlayer(
            videoUrl: videoUrl,
            title: ctx.name,
            autoPlay: true,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showInlineVideo = false;
                  });
                },
                icon: const Icon(LucideIcons.chevronUp, size: 16),
                label: const Text('Thu gọn Player'),
              ),
              IconButton(
                tooltip: _showInlineVideo ? 'Xem Toàn màn hình' : 'Bật Video',
                icon: const Icon(LucideIcons.maximize2, size: 18, color: Colors.amber),
                onPressed: () => _playVideoFullscreen(videoUrl, ctx.name),
              ),
            ],
          ),
        ] else ...[
          // Replay Video Banner Card
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showInlineVideo = true;
                    });
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.play_arrow_rounded, size: 32, color: Colors.black),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Phát Video tư liệu',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ctx.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Xem Fullscreen',
                  icon: const Icon(LucideIcons.externalLink, size: 18, color: Colors.white70),
                  onPressed: () => _openExternalVideo(videoUrl),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRelatedCharactersSection(HistoricalContext ctx, Color textMuted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Nhân vật liên quan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${ctx.characterIds.length} nhân vật',
              style: TextStyle(fontSize: 12, color: textMuted),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: ctx.characterIds.length,
            itemBuilder: (context, index) {
              final char = ctx.characterIds[index];
              final img = char.imageUrl ?? char.image;

              return Padding(
                padding: const EdgeInsets.only(right: 14.0),
                child: GestureDetector(
                  onTap: () {
                    if (char.id.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CharacterDetailScreen(characterId: char.id),
                        ),
                      );
                    }
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.darkSurface,
                        backgroundImage: (img != null && img.isNotEmpty)
                            ? CachedNetworkImageProvider(img)
                            : null,
                        child: (img == null || img.isEmpty)
                            ? Text(
                                char.name.isNotEmpty ? char.name[0].toUpperCase() : '?',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              )
                            : null,
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 72,
                        child: Text(
                          char.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textMuted;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: textMuted,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(fontSize: 14, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}
