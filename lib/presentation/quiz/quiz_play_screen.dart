import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'quiz_bloc.dart';
import 'quiz_result_screen.dart';
import '../../domain/entities/quiz.dart';
import '../../core/theme/app_theme.dart';

class QuizPlayScreen extends StatefulWidget {
  final QuizSession session;

  const QuizPlayScreen({super.key, required this.session});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  int _currentQuestionIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final accentColor = isDark ? AppColors.darkAccent : AppColors.lightAccent;
    final textMuted = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final questions = widget.session.questions;
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.session.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Bài trắc nghiệm này chưa có câu hỏi. Vui lòng thử lại sau.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final limitTime = widget.session.limitedTime > 0
        ? widget.session.limitedTime
        : widget.session.durationSeconds;

    return BlocConsumer<QuizBloc, QuizState>(
      listener: (context, state) {
        if (state.finishedResult != null) {
          // If quiz is finished, push the result screen and remove play screen from back stack
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<QuizBloc>(),
                child: QuizResultScreen(sessionId: widget.session.sessionId),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        final currentQuestion = questions[_currentQuestionIndex];
        final selectedAnswer = state.userAnswers[currentQuestion.questionId];

        // Format timer string MM:SS
        final remainingSeconds = (limitTime - state.elapsedSeconds).clamp(0, limitTime);
        final timerText = '${(remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(remainingSeconds % 60).toString().padLeft(2, '0')}';
        final progressVal = limitTime > 0 ? (state.elapsedSeconds / limitTime).clamp(0.0, 1.0) : 0.0;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.session.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                // Warning dialog on exit
                showDialog(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    title: const Text('Thoát làm bài?'),
                    content: const Text('Bài trắc nghiệm chưa hoàn thành sẽ không được lưu kết quả.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('Hủy'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogCtx); // Close dialog
                          context.read<QuizBloc>().add(ClearQuizStateRequested());
                          Navigator.pop(context); // Close play screen
                        },
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Thoát'),
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      timerText,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
              )
            ],
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timer Progress indicator bar
                LinearProgressIndicator(
                  value: progressVal,
                  backgroundColor: borderColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                ),
                
                // Question progress title
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Câu hỏi ${_currentQuestionIndex + 1}/${questions.length}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'Đã trả lời: ${state.userAnswers.length}/${questions.length}',
                        style: TextStyle(color: textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Question Box
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20.0),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            currentQuestion.content,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Options List
                        ...currentQuestion.options.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final optionText = entry.value;
                          final isSelected = selectedAnswer == idx;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: InkWell(
                              onTap: () {
                                context.read<QuizBloc>().add(
                                  AnswerSelected(
                                    questionId: currentQuestion.questionId,
                                    optionIndex: idx,
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: isSelected ? accentColor.withOpacity(0.12) : surfaceColor,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? accentColor : borderColor,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isSelected ? accentColor : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: isSelected ? accentColor : borderColor),
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        optionText,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),

                // Navigation buttons
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    border: Border(top: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      OutlinedButton(
                        onPressed: _currentQuestionIndex == 0
                            ? null
                            : () {
                                setState(() {
                                  _currentQuestionIndex--;
                                });
                              },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(100, 48),
                        ),
                        child: const Text('Quay lại'),
                      ),

                      // Next/Submit Button
                      ElevatedButton(
                        onPressed: state.isSubmitting
                            ? null
                            : () {
                                if (_currentQuestionIndex < questions.length - 1) {
                                  setState(() {
                                    _currentQuestionIndex++;
                                  });
                                } else {
                                  // Prompt submit confirmation
                                  showDialog(
                                    context: context,
                                    builder: (dialogCtx) => AlertDialog(
                                      title: const Text('Nộp bài trắc nghiệm?'),
                                      content: Text(
                                        'Bạn đã làm ${state.userAnswers.length}/${questions.length} câu. Bạn có muốn nộp bài ngay?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dialogCtx),
                                          child: const Text('Hủy'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(dialogCtx);
                                            context.read<QuizBloc>().add(SubmitQuizRequested());
                                          },
                                          style: TextButton.styleFrom(foregroundColor: accentColor),
                                          child: const Text('Nộp bài'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(140, 48),
                        ),
                        child: state.isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                _currentQuestionIndex < questions.length - 1 ? 'Câu tiếp theo' : 'Nộp bài',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
