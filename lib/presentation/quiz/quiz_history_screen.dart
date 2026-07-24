import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/lucide_icons.dart';

class QuizHistoryScreen extends StatelessWidget {
  const QuizHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final textMuted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final historyItems = [
      {'title': 'Trắc nghiệm Triều Lý', 'score': '9/10', 'date': '22/07/2026', 'duration': '3 phút 20 giây'},
      {'title': 'Sự kiện Bạch Đằng 938', 'score': '10/10', 'date': '20/07/2026', 'duration': '2 phút 45 giây'},
      {'title': 'Khởi nghĩa Hai Bà Trưng', 'score': '8/10', 'date': '18/07/2026', 'duration': '4 phút 10 giây'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử trắc nghiệm'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: historyItems.length,
        itemBuilder: (context, index) {
          final item = historyItems[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.emoji_events, color: accentColor, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title']!,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(LucideIcons.clock, size: 12, color: textMuted),
                            const SizedBox(width: 4),
                            Text(item['date']!, style: TextStyle(fontSize: 12, color: textMuted)),
                            const SizedBox(width: 12),
                            Icon(Icons.timer_outlined, size: 12, color: textMuted),
                            const SizedBox(width: 4),
                            Text(item['duration']!, style: TextStyle(fontSize: 12, color: textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      item['score']!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
