import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../domain/entities/character.dart';
import 'context_card.dart'; // import eraThemes mapping
import '../../core/theme/app_theme.dart';

class CharacterCard extends StatelessWidget {
  final Character char;
  final VoidCallback onPress;
  final String size; // 'sm' or 'lg'

  const CharacterCard({
    super.key,
    required this.char,
    required this.onPress,
    this.size = 'lg',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final et = eraThemes[char.era] ?? eraThemes[CharacterEra.ancient]!;
    final imageUri = char.imageUrl ?? char.image;

    if (size == 'sm') {
      return _buildSmallCard(context, et, imageUri);
    }
    return _buildLargeCard(context, et, imageUri);
  }

  // Horizontal Scroll card used on the Home screen
  Widget _buildSmallCard(BuildContext context, EraTheme et, String? imageUri) {
    return InkWell(
      onTap: onPress,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        height: 130,
        decoration: BoxDecoration(
          color: et.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Character portrait photo
            Positioned.fill(
              child: imageUri != null && imageUri.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUri,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _FallbackInitial(initial: char.name[0], color: et.glow),
                    )
                  : _FallbackInitial(initial: char.name[0], color: et.glow),
            ),

            // Black overlay gradient at the bottom for text readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.6],
                  ),
                ),
              ),
            ),

            // Name label at the bottom
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Text(
                char.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Grid list card used on character search and details list
  Widget _buildLargeCard(BuildContext context, EraTheme et, String? imageUri) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return InkWell(
      onTap: onPress,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail image block
            AspectRatio(
              aspectRatio: 1, // Square visual block
              child: Container(
                color: et.cardBg,
                child: imageUri != null && imageUri.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUri,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _FallbackInitial(initial: char.name[0], color: et.glow, fontSize: 36),
                      )
                    : _FallbackInitial(initial: char.name[0], color: et.glow, fontSize: 36),
              ),
            ),

            // Body info
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: et.bg,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      et.label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: et.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    char.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  if (char.title != null && char.title!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      char.title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
    this.fontSize = 26,
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
