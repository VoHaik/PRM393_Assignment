import 'dart:async';
import 'package:flutter/material.dart';
import 'package:historytalk_flutter/core/theme/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import '../../domain/entities/character.dart';
import '../../domain/entities/historical_context.dart';
import '../../domain/repositories/historical_context_repository.dart';
import '../../injection_container.dart';
import '../widgets/context_card.dart';
import '../../core/theme/app_theme.dart';

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
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _searchQuery = query.toLowerCase();
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

  void _applyFilters() {
    _filteredContexts = _allContexts.where((ctx) {
      final matchesSearch = ctx.name.toLowerCase().contains(_searchQuery) ||
          (ctx.description?.toLowerCase().contains(_searchQuery) ?? false);
      final matchesEra = _selectedEra == null || ctx.era == _selectedEra;
      return matchesSearch && matchesEra;
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
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: accentColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                          onChanged: _onSearchChanged,
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm bối cảnh lịch sử...',
                            hintStyle: TextStyle(color: textMuted),
                            border: InputBorder.none,
                          ),
                          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Era Filter Horizontal list
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    _buildEraTab('Tất cả', null, accentColor, surfaceColor, borderColor),
                    _buildEraTab('Cổ đại', CharacterEra.ancient, accentColor, surfaceColor, borderColor),
                    _buildEraTab('Trung đại', CharacterEra.medieval, accentColor, surfaceColor, borderColor),
                    _buildEraTab('Cận đại', CharacterEra.modern, accentColor, surfaceColor, borderColor),
                    _buildEraTab('Đương đại', CharacterEra.contemporary, accentColor, surfaceColor, borderColor),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Grid Content
              Expanded(
                child: _buildGridContent(),
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

  Widget _buildGridContent() {
    if (_isLoading) {
      return _buildSkeletonLoader();
    }
    if (_isError) {
      return const Center(
        child: Text('Không thể tải dữ liệu. Vui lòng thử lại.'),
      );
    }
    if (_filteredContexts.isEmpty) {
      return const Center(
        child: Text('Không tìm thấy bối cảnh lịch sử nào.'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78, // Aligned with React Native card proportions
      ),
      itemCount: _filteredContexts.length,
      itemBuilder: (context, index) {
        final ctx = _filteredContexts[index];
        return ContextCard(
          ctx: ctx,
          onPress: () {
            // Navigate to context detail screen
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text(ctx.name)),
                  body: Center(child: Text('Chi tiết bối cảnh: ${ctx.name}')),
                ),
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
        childAspectRatio: 0.78,
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
