import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/lucide_icons.dart';
import '../../domain/entities/historical_context.dart';
import '../historical_context/historical_context_detail_screen.dart';
import 'context_card.dart';

int sortYear(HistoricalContext ctx) {
  final y = ctx.year ?? ctx.startYear ?? ctx.endYear;
  if (y == null) return 999999;
  return ctx.isBC == true ? -y.abs() : y;
}

class ContextTimelineWidget extends StatefulWidget {
  final List<HistoricalContext> contexts;

  const ContextTimelineWidget({
    super.key,
    required this.contexts,
  });

  @override
  State<ContextTimelineWidget> createState() => _ContextTimelineWidgetState();
}

class _ContextTimelineWidgetState extends State<ContextTimelineWidget> {
  late List<HistoricalContext> _sortedEvents;
  late PageController _pageController;
  final ScrollController _stripController = ScrollController();
  int _activeIdx = 0;

  @override
  void initState() {
    super.initState();
    _sortEvents();
    _pageController = PageController(viewportFraction: 0.88, initialPage: 0);
  }

  @override
  void didUpdateWidget(covariant ContextTimelineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contexts != widget.contexts) {
      _sortEvents();
    }
  }

  void _sortEvents() {
    _sortedEvents = List.from(widget.contexts)
      ..sort((a, b) => sortYear(a).compareTo(sortYear(b)));
    if (_activeIdx >= _sortedEvents.length) {
      _activeIdx = _sortedEvents.isEmpty ? 0 : _sortedEvents.length - 1;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _stripController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _activeIdx = index;
    });
    // Scroll strip to center selected index
    if (_stripController.hasClients) {
      const itemWidth = 84.0;
      final targetOffset = (index * itemWidth) - (MediaQuery.of(context).size.width / 2) + (itemWidth / 2);
      _stripController.animateTo(
        targetOffset.clamp(0.0, _stripController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _selectIndex(int index) {
    if (index < 0 || index >= _sortedEvents.length) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_sortedEvents.isEmpty) {
      return const Center(child: Text('Không có bối cảnh lịch sử nào.'));
    }

    return Column(
      children: [
        // ── Timeline Header & Controls ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mốc lịch sử (${_activeIdx + 1}/${_sortedEvents.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(LucideIcons.chevronLeft, size: 20),
                    onPressed: _activeIdx > 0 ? () => _selectIndex(_activeIdx - 1) : null,
                  ),
                  IconButton(
                    icon: Icon(LucideIcons.chevronRight, size: 20),
                    onPressed: _activeIdx < _sortedEvents.length - 1 ? () => _selectIndex(_activeIdx + 1) : null,
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Timeline Horizontal Strip ──
        SizedBox(
          height: 54,
          child: ListView.builder(
            controller: _stripController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _sortedEvents.length,
            itemBuilder: (context, index) {
              final ctx = _sortedEvents[index];
              final isSelected = index == _activeIdx;
              final yearTxt = formatContextYear(ctx);
              final et = eraThemes[ctx.era] ?? eraThemes[eraThemes.keys.first]!;

              return GestureDetector(
                onTap: () => _selectIndex(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? et.bg : (isDark ? const Color(0xFF1E1E2E) : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? et.text : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        yearTxt.isNotEmpty ? yearTxt : 'Sự kiện',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? et.text : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? et.text : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // ── Card PageView ──
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _sortedEvents.length,
            itemBuilder: (context, index) {
              final ctx = _sortedEvents[index];
              final et = eraThemes[ctx.era] ?? eraThemes[eraThemes.keys.first]!;
              final yearTxt = formatContextYear(ctx);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Image Hero Header
                        Expanded(
                          flex: 5,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ctx.image != null && ctx.image!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: ctx.image!,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => Container(
                                          color: et.cardBg,
                                          child: Center(
                                            child: Text(
                                              ctx.name[0].toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 64,
                                                fontWeight: FontWeight.w900,
                                                color: et.glow.withOpacity(0.4),
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
                                              fontSize: 64,
                                              fontWeight: FontWeight.w900,
                                              color: et.glow.withOpacity(0.4),
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: et.bg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    et.label,
                                    style: TextStyle(
                                      color: et.text,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              if (ctx.videoUrl != null && ctx.videoUrl!.trim().isNotEmpty)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.amber, width: 1),
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(LucideIcons.film, size: 12, color: Colors.amber),
                                        SizedBox(width: 4),
                                        Text(
                                          'Có Video',
                                          style: TextStyle(
                                            color: Colors.amber,
                                            fontSize: 11,
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

                        // Info Body
                        Expanded(
                          flex: 6,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ctx.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (yearTxt.isNotEmpty || (ctx.location != null && ctx.location!.isNotEmpty))
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.clock, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          [yearTxt, ctx.location].where((s) => s != null && s.isNotEmpty).join(' · '),
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 8),
                                if (ctx.description != null && ctx.description!.isNotEmpty)
                                  Expanded(
                                    child: Text(
                                      ctx.description!,
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.white70),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => HistoricalContextDetailScreen(context: ctx),
                                        ),
                                      );
                                    },
                                    icon: Icon(LucideIcons.arrowRight, size: 16),
                                    label: const Text('Xem chi tiết bối cảnh'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: et.bg,
                                      foregroundColor: et.text,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
