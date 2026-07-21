import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:historytalk_flutter/core/theme/lucide_icons.dart';
import 'quiz_bloc.dart';
import 'quiz_play_screen.dart';
import 'quiz_result_screen.dart';
import '../../domain/entities/quiz.dart';
import '../../core/theme/app_theme.dart';
import '../../injection_container.dart';

class QuizListScreen extends StatefulWidget {
  const QuizListScreen({super.key});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final QuizBloc _quizBloc;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _quizBloc = sl<QuizBloc>()
      ..add(FetchQuizzesRequested())
      ..add(FetchHistoryRequested());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final textMuted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return BlocProvider.value(
      value: _quizBloc,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trắc nghiệm lịch sử', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: theme.textTheme.bodyLarge?.color,
          bottom: TabBar(
            controller: _tabController,
            labelColor: accentColor,
            unselectedLabelColor: textMuted,
            indicatorColor: accentColor,
            tabs: const [
              Tab(text: 'Danh sách bài tập'),
              Tab(text: 'Lịch sử làm bài'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildQuizzesTab(accentColor, surfaceColor, borderColor, textMuted),
            _buildHistoryTab(accentColor, surfaceColor, borderColor, textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizzesTab(Color accentColor, Color surfaceColor, Color borderColor, Color textMuted) {
    return BlocConsumer<QuizBloc, QuizState>(
      listenWhen: (previous, current) {
        final previousSessionId = previous.activeSession?.sessionId;
        final currentSessionId = current.activeSession?.sessionId;
        return currentSessionId != null && currentSessionId != previousSessionId;
      },
      listener: (context, state) {
        if (state.activeSession != null) {
          // If a quiz session is successfully started, open QuizPlayScreen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: _quizBloc,
                child: QuizPlayScreen(session: state.activeSession!),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.isQuizzesLoading && state.quizzes.isEmpty) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }

        if (state.quizzes.isEmpty) {
          return const Center(child: Text('Không có bài trắc nghiệm nào.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: state.quizzes.length,
          itemBuilder: (context, index) {
            final quiz = state.quizzes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Card(
                color: surfaceColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: borderColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: quiz.level == QuizLevel.easy
                                  ? Colors.green.shade50
                                  : quiz.level == QuizLevel.medium
                                      ? Colors.amber.shade50
                                      : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              quiz.level == QuizLevel.easy
                                  ? 'DỄ'
                                  : quiz.level == QuizLevel.medium
                                      ? 'TRUNG BÌNH'
                                      : 'KHÓ',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: quiz.level == QuizLevel.easy
                                    ? Colors.green
                                    : quiz.level == QuizLevel.medium
                                        ? Colors.amber.shade800
                                        : Colors.red,
                              ),
                            ),
                          ),
                          Text(
                            'Lượt chơi: ${quiz.playCount}',
                            style: TextStyle(fontSize: 12, color: textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        quiz.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      if (quiz.chapterTitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Chương ${quiz.chapterNumber}: ${quiz.chapterTitle}',
                          style: TextStyle(fontSize: 13, color: textMuted),
                        ),
                      ],
                      if (quiz.description != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          quiz.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: textMuted),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          _quizBloc.add(StartQuizSessionRequested(quizId: quiz.quizId));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Text('Bắt đầu làm bài', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryTab(Color accentColor, Color surfaceColor, Color borderColor, Color textMuted) {
    return BlocBuilder<QuizBloc, QuizState>(
      builder: (context, state) {
        if (state.isHistoryLoading && state.history.isEmpty) {
          return Center(child: CircularProgressIndicator(color: accentColor));
        }

        if (state.history.isEmpty) {
          return const Center(child: Text('Chưa có lịch sử làm bài nào.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: state.history.length,
          itemBuilder: (context, index) {
            final item = state.history[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: InkWell(
                onTap: () {
                  // Navigate to QuizResultScreen directly with sessionId
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: _quizBloc,
                        child: QuizResultScreen(sessionId: item.sessionId),
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: surfaceColor,
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
                              item.quizTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đạt: ${item.score}/${item.totalQuestions} câu (${item.percentage.toStringAsFixed(1)}%)',
                              style: TextStyle(fontSize: 12, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.percentage >= 80
                              ? Colors.green.shade50
                              : item.percentage >= 50
                                  ? Colors.amber.shade50
                                  : Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.percentage >= 80
                              ? Icons.check_circle
                              : item.percentage >= 50
                                  ? Icons.info
                                  : Icons.cancel,
                          color: item.percentage >= 80
                              ? Colors.green
                              : item.percentage >= 50
                                  ? Colors.amber.shade800
                                  : Colors.red,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
