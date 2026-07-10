import 'package:flutter/material.dart';
import 'package:historytalk_flutter/core/theme/lucide_icons.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/repositories/quiz_repository.dart';
import '../../injection_container.dart';
import '../../core/theme/app_theme.dart';

class QuizResultScreen extends StatefulWidget {
  final String sessionId;

  const QuizResultScreen({super.key, required this.sessionId});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  final QuizRepository _quizRepository = sl<QuizRepository>();
  QuizResultDetail? _detail;
  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _loadResultDetail();
  }

  Future<void> _loadResultDetail() async {
    try {
      final detail = await _quizRepository.getResultDetail(widget.sessionId);
      setState(() {
        _detail = detail;
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _isError = true;
      });
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết quả trắc nghiệm', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.textTheme.bodyLarge?.color,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Pop back to the main list
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _buildBody(accentColor, surfaceColor, borderColor, textMuted),
    );
  }

  Widget _buildBody(Color accentColor, Color surfaceColor, Color borderColor, Color textMuted) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    if (_isError || _detail == null) {
      return const Center(child: Text('Không thể tải kết quả chi tiết.'));
    }

    final detail = _detail!;
    final isPassed = detail.percentage >= 50;

    return Column(
      children: [
        // Summary Header Banner
        Container(
          padding: const EdgeInsets.all(24.0),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isPassed ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isPassed ? Colors.green.shade200 : Colors.red.shade200),
          ),
          child: Column(
            children: [
              Icon(
                isPassed ? LucideIcons.trophy : Icons.warning,
                color: isPassed ? Colors.green : Colors.red,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                isPassed ? 'Hoàn thành xuất sắc!' : 'Cần cố gắng thêm!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isPassed ? Colors.green.shade800 : Colors.red.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Điểm số: ${detail.score}/${detail.totalQuestions} câu (${detail.percentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isPassed ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),

        // Title line
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Chi tiết đáp án',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),

        // Answers breakdown list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: detail.questions.length,
            itemBuilder: (context, qIdx) {
              final q = detail.questions[qIdx];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Question Number & Content
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: q.correct ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'CÂU ${q.orderIndex + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: q.correct ? Colors.green : Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              q.content,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Options
                      ...q.options.asMap().entries.map((optEntry) {
                        final oIdx = optEntry.key;
                        final optionText = optEntry.value;

                        final isSelected = q.selectedAnswer == oIdx;
                        final isCorrectOption = q.correctAnswer == oIdx;

                        Color optBgColor = Colors.transparent;
                        Color optBorderColor = borderColor;
                        IconData? checkIcon;
                        Color? iconColor;

                        if (isCorrectOption) {
                          optBgColor = Colors.green.shade50;
                          optBorderColor = Colors.green;
                          checkIcon = Icons.check_circle;
                          iconColor = Colors.green;
                        } else if (isSelected && !q.correct) {
                          optBgColor = Colors.red.shade50;
                          optBorderColor = Colors.red;
                          checkIcon = Icons.cancel;
                          iconColor = Colors.red;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: optBgColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: optBorderColor),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    optionText,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isCorrectOption || isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (checkIcon != null) ...[
                                  const SizedBox(width: 8),
                                  Icon(checkIcon, color: iconColor, size: 16),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),

                      // Explanation box
                      if (q.explanation != null && q.explanation!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Giải thích:',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accentColor),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                q.explanation!,
                                style: const TextStyle(fontSize: 12, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                      ],
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
