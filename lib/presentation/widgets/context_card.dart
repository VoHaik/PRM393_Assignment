import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:historytalk_flutter/core/theme/lucide_icons.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/historical_context.dart';

// Era Visual Configuration
class EraTheme {
  final Color bg;
  final Color text;
  final Color glow;
  final Color cardBg;
  final String label;

  const EraTheme({
    required this.bg,
    required this.text,
    required this.glow,
    required this.cardBg,
    required this.label,
  });
}

const Map<CharacterEra, EraTheme> eraThemes = {
  CharacterEra.ancient: EraTheme(
    bg: Color(0xFFFCE8C6),
    text: Color(0xFF92400E),
    glow: Color(0xFFFCD34D),
    cardBg: Color(0xFF1C0E06),
    label: 'Cổ đại',
  ),
  CharacterEra.medieval: EraTheme(
    bg: Color(0xFFEAE0FB),
    text: Color(0xFF6D28D9),
    glow: Color(0xFFC4B5FD),
    cardBg: Color(0xFF120828),
    label: 'Trung đại',
  ),
  CharacterEra.modern: EraTheme(
    bg: Color(0xFFCFF3EA),
    text: Color(0xFF0F766E),
    glow: Color(0xFF5EEAD4),
    cardBg: Color(0xFF061A18),
    label: 'Cận đại',
  ),
  CharacterEra.contemporary: EraTheme(
    bg: Color(0xFFDCE7FB),
    text: Color(0xFF1D4ED8),
    glow: Color(0xFF93C5FD),
    cardBg: Color(0xFF071020),
    label: 'Hiện đại',
  ),
};

// Category Configuration
const Map<ContextCategory, String> categoryLabels = {
  ContextCategory.war: 'Chiến tranh',
  ContextCategory.politics: 'Chính trị',
  ContextCategory.culture: 'Văn hóa',
  ContextCategory.science: 'Khoa học',
  ContextCategory.religion: 'Tôn giáo',
  ContextCategory.other: 'Khác',
};

const Map<ContextCategory, Color> categoryColors = {
  ContextCategory.war: Color(0xFFEF4444),
  ContextCategory.politics: Color(0xFFA855F7),
  ContextCategory.culture: Color(0xFFF59E0B),
  ContextCategory.science: Color(0xFF06B6D4),
  ContextCategory.religion: Color(0xFF10B981),
  ContextCategory.other: Color(0xFF6B7280),
};

String formatContextYear(HistoricalContext ctx) {
  if (ctx.yearLabel != null && ctx.yearLabel!.isNotEmpty) {
    return ctx.yearLabel!;
  }
  final bc = ctx.isBC == true ? ' TCN' : '';
  if (ctx.year != null) return 'Năm ${ctx.year}$bc';
  if (ctx.startYear != null && ctx.endYear != null) {
    return '${ctx.startYear} – ${ctx.endYear}$bc';
  }
  if (ctx.startYear != null) return 'Từ ${ctx.startYear}$bc';
  if (ctx.endYear != null) return 'Đến ${ctx.endYear}$bc';
  return '';
}

class ContextCard extends StatelessWidget {
  final HistoricalContext ctx;
  final VoidCallback onPress;
  final String variant; // 'compact' or 'full'

  const ContextCard({
    super.key,
    required this.ctx,
    required this.onPress,
    this.variant = 'full',
  });

  @override
  Widget build(BuildContext context) {
    if (variant == 'compact') {
      return _CompactRow(ctx: ctx, onPress: onPress);
    }
    return _FullCard(ctx: ctx, onPress: onPress);
  }
}

// ─── Compact row (Home list preview) ──────────────────────────────────────────
class _CompactRow extends StatelessWidget {
  final HistoricalContext ctx;
  final VoidCallback onPress;

  const _CompactRow({required this.ctx, required this.onPress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final et = eraThemes[ctx.era] ?? eraThemes[CharacterEra.ancient]!;
    final imageUri = ctx.image;
    final yearTxt = formatContextYear(ctx);

    return InkWell(
      onTap: onPress,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 50,
              height: 56,
              decoration: BoxDecoration(
                color: et.cardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUri != null && imageUri.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUri,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _FallbackInitial(initial: ctx.name[0], color: et.glow),
                    )
                  : _FallbackInitial(initial: ctx.name[0], color: et.glow),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Era Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: et.bg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      et.label,
                      style: TextStyle(color: et.text, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ctx.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  if (yearTxt.isNotEmpty || (ctx.location != null && ctx.location!.isNotEmpty))
                    Row(
                      children: [
                        if (ctx.location != null && ctx.location!.isNotEmpty) ...[
                          Icon(LucideIcons.mapPin, size: 10, color: theme.textTheme.bodyMedium?.color),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            [yearTxt, ctx.location].where((s) => s != null && s.isNotEmpty).join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight, size: 16, color: theme.textTheme.bodyMedium?.color),
          ],
        ),
      ),
    );
  }
}

// ─── Full grid card (/explorer grid screen) ──────────────────────────────────
class _FullCard extends StatelessWidget {
  final HistoricalContext ctx;
  final VoidCallback onPress;

  const _FullCard({required this.ctx, required this.onPress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final et = eraThemes[ctx.era] ?? eraThemes[CharacterEra.ancient]!;
    final imageUri = ctx.image;
    final yearTxt = formatContextYear(ctx);

    return InkWell(
      onTap: onPress,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      color: et.cardBg,
                      child: imageUri != null && imageUri.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: imageUri,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _FallbackInitial(initial: ctx.name[0], color: et.glow, fontSize: 36),
                            )
                          : _FallbackInitial(initial: ctx.name[0], color: et.glow, fontSize: 36),
                    ),
                  ),
                  if (ctx.videoUrl != null && ctx.videoUrl!.trim().isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(LucideIcons.film, size: 10, color: Colors.amber),
                            SizedBox(width: 3),
                            Text(
                              'Video',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        et.label,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: et.text),
                      ),
                      if (ctx.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: categoryColors[ctx.category]!.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            categoryLabels[ctx.category]!,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: categoryColors[ctx.category],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ctx.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  if (yearTxt.isNotEmpty || (ctx.location != null && ctx.location!.isNotEmpty))
                    Text(
                      [yearTxt, ctx.location].where((s) => s != null && s.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackInitial extends StatelessWidget {
  final String initial;
  final Color color;
  final double fontSize;

  const _FallbackInitial({
    required this.initial,
    required this.color,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initial.toUpperCase(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          color: color.withOpacity(0.65),
        ),
      ),
    );
  }
}
