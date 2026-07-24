import 'dart:async';
import 'package:flutter/material.dart';
import 'package:historytalk_flutter/core/theme/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/historical_context.dart';
import '../../domain/repositories/historical_context_repository.dart';
import '../../injection_container.dart';
import '../widgets/context_card.dart';
import '../widgets/context_timeline_widget.dart';
import '../../core/theme/app_theme.dart';
import '../historical_context/historical_context_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final HistoricalContextRepository _repository = sl<HistoricalContextRepository>();
  
  List<HistoricalContext> _allContexts = [];
  List<HistoricalContext> _filteredContexts = [];
  bool _isLoading = true;
  bool _isError = false;

  String _searchQuery = '';
  CharacterEra? _selectedEra; // null means 'ALL'
  ContextCategory? _selectedCategory;
  bool _onlyVideo = false;
  bool _isTimelineView = true;
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });
    try {
      final data = await _repository.getContexts();
      setState(() {
        _allContexts = data;
        _applyFilters();
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _isError = true;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = query.trim().toLowerCase();
        _applyFilters();
      });
    });
  }

  void _onEraChanged(CharacterEra? era) {
    setState(() {
      _selectedEra = era;
      _applyFilters();
    });
  }

  void _onCategoryChanged(ContextCategory? cat) {
    setState(() {
      _selectedCategory = cat;
      _applyFilters();
    });
  }

  void _toggleOnlyVideo() {
    setState(() {
      _onlyVideo = !_onlyVideo;
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredContexts = _allContexts.where((ctx) {
      final matchesSearch = _searchQuery.isEmpty ||
          ctx.name.toLowerCase().contains(_searchQuery) ||
          (ctx.description?.toLowerCase().contains(_searchQuery) ?? false) ||
          (ctx.location?.toLowerCase().contains(_searchQuery) ?? false);

      final matchesEra = _selectedEra == null || ctx.era == _selectedEra;
      final matchesCategory = _selectedCategory == null || ctx.category == _selectedCategory;
      final matchesVideo = !_onlyVideo || (ctx.videoUrl != null && ctx.videoUrl!.trim().isNotEmpty);

      return matchesSearch && matchesEra && matchesCategory && matchesVideo;
    }).toList();
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
      appBar: AppBar(
        title: const Text('Bối cảnh lịch sử', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.textTheme.bodyLarge?.color,
        actions: [
          IconButton(
            tooltip: _isTimelineView ? 'Xem dạng Lưới' : 'Xem Trục thời gian',
            icon: Icon(
              _isTimelineView ? LucideIcons.layoutGrid : LucideIcons.clock,
              color: accentColor,
            ),
            onPressed: () {
              setState(() {
                _isTimelineView = !_isTimelineView;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: accentColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Input Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Icon(LucideIcons.search, size: 18, color: Colors.grey),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Tìm bối cảnh, sự kiện, địa danh...',
                            hintStyle: TextStyle(color: textMuted, fontSize: 14),
                            border: InputBorder.none,
                          ),
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 16, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // Horizontal Filters (Era & Video & Category)
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    // Video Quick Filter Chip
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        avatar: Icon(
                          LucideIcons.film,
                          size: 14,
                          color: _onlyVideo ? Colors.black : Colors.amber,
                        ),
                        label: const Text('Có Video', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        selected: _onlyVideo,
                        onSelected: (_) => _toggleOnlyVideo(),
                        selectedColor: Colors.amber,
                        backgroundColor: surfaceColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: _onlyVideo ? Colors.amber : borderColor),
                        ),
                        showCheckmark: false,
                      ),
                    ),
                    _buildEraTab('Tất cả thời kỳ', null, accentColor, surfaceColor, borderColor),
                    _buildEraTab('Cổ đại', CharacterEra.ancient, accentColor, surfaceColor, borderColor),
                    _buildEraTab('Trung đại', CharacterEra.medieval, accentColor, surfaceColor, borderColor),
                    _buildEraTab('Cận đại', CharacterEra.modern, accentColor, surfaceColor, borderColor),
                    _buildEraTab('Đương đại', CharacterEra.contemporary, accentColor, surfaceColor, borderColor),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Results count header
              if (!_isLoading && !_isError)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tìm thấy ${_filteredContexts.length} bối cảnh',
                        style: TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _isTimelineView ? 'Chế độ Trục thời gian' : 'Chế độ Lưới',
                        style: TextStyle(fontSize: 12, color: accentColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),

              // Content View (Grid vs Timeline)
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEraTab(
    String label,
    CharacterEra? era,
    Color activeColor,
    Color surfaceColor,
    Color borderColor,
  ) {
    final isActive = _selectedEra == era;
    final theme = Theme.of(context);
    final et = era != null ? eraThemes[era] : null;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive
                ? (et != null ? et.text : Colors.white)
                : theme.textTheme.bodyMedium?.color,
          ),
        ),
        selected: isActive,
        onSelected: (_) => _onEraChanged(era),
        selectedColor: et != null ? et.bg : activeColor,
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isActive
                ? (et != null ? et.text.withOpacity(0.3) : Colors.transparent)
                : borderColor,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildSkeletonLoader();
    }
    if (_isError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text('Không thể tải dữ liệu bối cảnh lịch sử.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }
    if (_filteredContexts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.searchX, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Không tìm thấy bối cảnh lịch sử phù hợp.'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedEra = null;
                  _selectedCategory = null;
                  _onlyVideo = false;
                  _applyFilters();
                });
              },
              child: const Text('Xóa bộ lọc tìm kiếm'),
            ),
          ],
        ),
      );
    }

    if (_isTimelineView) {
      return ContextTimelineWidget(contexts: _filteredContexts);
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.64,
      ),
      itemCount: _filteredContexts.length,
      itemBuilder: (context, index) {
        final ctx = _filteredContexts[index];
        return ContextCard(
          ctx: ctx,
          onPress: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HistoricalContextDetailScreen(context: ctx),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.73,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        );
      },
    );
  }
}
