import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/quiz.dart';
import '../../domain/repositories/quiz_repository.dart';

const Object _sentinel = Object();

// --- EVENTS ---
abstract class QuizEvent {}

class FetchQuizzesRequested extends QuizEvent {}

class StartQuizSessionRequested extends QuizEvent {
  final String quizId;
  StartQuizSessionRequested({required this.quizId});
}

class AnswerSelected extends QuizEvent {
  final String questionId;
  final int optionIndex;
  AnswerSelected({required this.questionId, required this.optionIndex});
}

class TimerTicked extends QuizEvent {}

class SubmitQuizRequested extends QuizEvent {}

class FetchHistoryRequested extends QuizEvent {
  final int page;
  final int size;
  FetchHistoryRequested({this.page = 0, this.size = 10});
}

class ClearQuizStateRequested extends QuizEvent {}

// --- STATE ---
class QuizState {
  final List<Quiz> quizzes;
  final bool isQuizzesLoading;
  
  final QuizSession? activeSession;
  final Map<String, int> userAnswers; // questionId -> optionIndex
  final int elapsedSeconds;
  
  final bool isSubmitting;
  final QuizResult? finishedResult;
  
  final List<MyResult> history;
  final bool isHistoryLoading;
  final String? error;

  QuizState({
    this.quizzes = const [],
    this.isQuizzesLoading = false,
    this.activeSession,
    this.userAnswers = const {},
    this.elapsedSeconds = 0,
    this.isSubmitting = false,
    this.finishedResult,
    this.history = const [],
    this.isHistoryLoading = false,
    this.error,
  });

  QuizState copyWith({
    List<Quiz>? quizzes,
    bool? isQuizzesLoading,
    Object? activeSession = _sentinel,
    Map<String, int>? userAnswers,
    int? elapsedSeconds,
    bool? isSubmitting,
    Object? finishedResult = _sentinel,
    List<MyResult>? history,
    bool? isHistoryLoading,
    Object? error = _sentinel,
  }) {
    return QuizState(
      quizzes: quizzes ?? this.quizzes,
      isQuizzesLoading: isQuizzesLoading ?? this.isQuizzesLoading,
      activeSession: identical(activeSession, _sentinel)
          ? this.activeSession
          : activeSession as QuizSession?,
      userAnswers: userAnswers ?? this.userAnswers,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      finishedResult: identical(finishedResult, _sentinel)
          ? this.finishedResult
          : finishedResult as QuizResult?,
      history: history ?? this.history,
      isHistoryLoading: isHistoryLoading ?? this.isHistoryLoading,
      error: identical(error, _sentinel) ? this.error : error as String?,
    );
  }
}

// --- BLOC ---
class QuizBloc extends Bloc<QuizEvent, QuizState> {
  final QuizRepository _quizRepository;
  Timer? _timer;

  QuizBloc({required QuizRepository quizRepository})
      : _quizRepository = quizRepository,
        super(QuizState()) {
    on<FetchQuizzesRequested>(_onFetchQuizzesRequested);
    on<StartQuizSessionRequested>(_onStartQuizSessionRequested);
    on<AnswerSelected>(_onAnswerSelected);
    on<TimerTicked>(_onTimerTicked);
    on<SubmitQuizRequested>(_onSubmitQuizRequested);
    on<FetchHistoryRequested>(_onFetchHistoryRequested);
    on<ClearQuizStateRequested>(_onClearQuizStateRequested);
  }

  Future<void> _onFetchQuizzesRequested(
      FetchQuizzesRequested event, Emitter<QuizState> emit) async {
    emit(state.copyWith(isQuizzesLoading: true));
    try {
      final quizzes = await _quizRepository.getQuizzes();
      emit(state.copyWith(quizzes: quizzes, isQuizzesLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isQuizzesLoading: false));
    }
  }

  Future<void> _onStartQuizSessionRequested(
      StartQuizSessionRequested event, Emitter<QuizState> emit) async {
    _timer?.cancel();
    emit(state.copyWith(
      isQuizzesLoading: true,
      finishedResult: null,
      error: null,
    ));
    try {
      final session = await _quizRepository.startQuiz(event.quizId);
      emit(state.copyWith(
        activeSession: session,
        userAnswers: {},
        elapsedSeconds: 0,
        isQuizzesLoading: false,
      ));

      if (session.questions.isNotEmpty) {
        // Start the timer
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          add(TimerTicked());
        });
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isQuizzesLoading: false));
    }
  }

  void _onAnswerSelected(AnswerSelected event, Emitter<QuizState> emit) {
    final updatedAnswers = Map<String, int>.from(state.userAnswers)
      ..[event.questionId] = event.optionIndex;
    emit(state.copyWith(userAnswers: updatedAnswers));
  }

  void _onTimerTicked(TimerTicked event, Emitter<QuizState> emit) {
    if (state.activeSession == null) {
      _timer?.cancel();
      return;
    }
    
    final newElapsed = state.elapsedSeconds + 1;
    final limit = state.activeSession!.limitedTime > 0
        ? state.activeSession!.limitedTime
        : state.activeSession!.durationSeconds;

    if (limit > 0 && newElapsed >= limit) {
      _timer?.cancel();
      emit(state.copyWith(elapsedSeconds: limit));
      add(SubmitQuizRequested());
    } else {
      emit(state.copyWith(elapsedSeconds: newElapsed));
    }
  }

  Future<void> _onSubmitQuizRequested(
      SubmitQuizRequested event, Emitter<QuizState> emit) async {
    _timer?.cancel();
    if (state.activeSession == null) return;
    
    emit(state.copyWith(isSubmitting: true));
    try {
      // Map userAnswers map to List<SubmitAnswerItem>
      final answersList = state.userAnswers.entries.map((entry) {
        return SubmitAnswerItem(
          questionId: entry.key,
          selectedAnswer: entry.value,
        );
      }).toList();

      // For unanswered questions, submit -1
      for (final q in state.activeSession!.questions) {
        if (!state.userAnswers.containsKey(q.questionId)) {
          answersList.add(SubmitAnswerItem(
            questionId: q.questionId,
            selectedAnswer: -1,
          ));
        }
      }

      final result = await _quizRepository.submitQuiz(
        sessionId: state.activeSession!.sessionId,
        answers: answersList,
      );

      emit(state.copyWith(
        finishedResult: result,
        activeSession: null,
        userAnswers: {},
        elapsedSeconds: 0,
        isSubmitting: false,
      ));

      // Refresh quiz history automatically after submission
      add(FetchHistoryRequested());
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isSubmitting: false));
    }
  }

  Future<void> _onFetchHistoryRequested(
      FetchHistoryRequested event, Emitter<QuizState> emit) async {
    emit(state.copyWith(isHistoryLoading: true));
    try {
      final history = await _quizRepository.getHistory(page: event.page, size: event.size);
      emit(state.copyWith(history: history, isHistoryLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isHistoryLoading: false));
    }
  }

  void _onClearQuizStateRequested(ClearQuizStateRequested event, Emitter<QuizState> emit) {
    _timer?.cancel();
    emit(state.copyWith(activeSession: null, finishedResult: null, userAnswers: {}, elapsedSeconds: 0));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
