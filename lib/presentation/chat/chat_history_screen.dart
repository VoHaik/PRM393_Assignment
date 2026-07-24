import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/lucide_icons.dart';

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final textMuted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final chatSessions = [
      {
        'character': 'Trần Hưng Đạo',
        'lastMsg': 'Bản Hịch Tướng Sĩ được viết nhằm khích lệ tinh thần các tướng sĩ...',
        'time': '10 phút trước',
        'unread': false,
      },
      {
        'character': 'Quang Trung - Nguyễn Huệ',
        'lastMsg': 'Đại phá quân Thanh vào dịp Tết Kỷ Dậu 1789...',
        'time': 'Hôm qua',
        'unread': false,
      },
      {
        'character': 'Hai Bà Trưng',
        'lastMsg': 'Khởi nghĩa dấy lên tại Mê Linh năm 40 SCN...',
        'time': '3 ngày trước',
        'unread': false,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử trò chuyện'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: chatSessions.length,
        itemBuilder: (context, index) {
          final session = chatSessions[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: accentColor.withValues(alpha: 0.1),
                child: Icon(LucideIcons.user, color: accentColor),
              ),
              title: Text(
                session['character'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  session['lastMsg'] as String,
                  style: TextStyle(fontSize: 13, color: textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              trailing: Text(
                session['time'] as String,
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }
}
