# Quiz Freeze Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the quiz start/timer freeze by preventing repeated quiz-screen navigation and making quiz session cleanup actually clear nullable state.

**Architecture:** Keep the fix inside the presentation layer. `QuizBloc` remains the single state holder for quiz list, active session, answers, elapsed time, submit state, and history. `QuizListScreen` reacts only to the transition into a new active session; `QuizPlayScreen` remains a view over the active session passed at navigation time.

**Tech Stack:** Flutter, Dart, `flutter_bloc ^8.1.6`, GetIt dependency injection.

## Global Constraints

- Do not modify repository, API, DI, domain entity, generated platform, or dependency files for this bug.
- Preserve the existing BLoC pattern and `BlocProvider.value` navigation style.
- Keep the change scoped to `lib/presentation/quiz/quiz_bloc.dart`, `lib/presentation/quiz/quiz_list_screen.dart`, and `lib/presentation/quiz/quiz_play_screen.dart`.
- Do not introduce new packages.
- Existing dirty generated/platform files must be left untouched.

---

## File Structure

- Modify `lib/presentation/quiz/quiz_bloc.dart`: add nullable-clear support to `QuizState.copyWith`; ensure clear/submit/start flows use it correctly.
- Modify `lib/presentation/quiz/quiz_list_screen.dart`: add `listenWhen` to prevent repeated navigation while timer ticks.
- Modify `lib/presentation/quiz/quiz_play_screen.dart`: handle sessions with no questions before reading `questions[_currentQuestionIndex]`.

---

### Task 1: Make QuizState Nullable Fields Clearable

**Files:**
- Modify: `lib/presentation/quiz/quiz_bloc.dart`

**Interfaces:**
- Consumes: existing `QuizState.copyWith(...)`.
- Produces: `QuizState.copyWith(...)` that supports explicit clearing of `activeSession`, `finishedResult`, and `error`.

- [ ] **Step 1: Inspect current nullable state usage**

Run:

```powershell
rg -n "copyWith\\(|activeSession: null|finishedResult: null|error:" lib\presentation\quiz\quiz_bloc.dart lib\presentation\quiz
```

Expected: output includes `activeSession: null` in submit and clear paths, and `finishedResult: null` in start/clear paths.

- [ ] **Step 2: Update copyWith signature**

In `lib/presentation/quiz/quiz_bloc.dart`, replace the `copyWith` method with this implementation:

```dart
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
```

Add this top-level constant above `class QuizState`:

```dart
const Object _sentinel = Object();
```

- [ ] **Step 3: Clear stale errors when starting a quiz**

In `_onStartQuizSessionRequested`, ensure the loading emit clears old submit result and error:

```dart
    emit(state.copyWith(
      isQuizzesLoading: true,
      finishedResult: null,
      error: null,
    ));
```

- [ ] **Step 4: Verify state cleanup paths are now meaningful**

Confirm these existing calls remain present:

```dart
activeSession: null,
finishedResult: result,
```

and:

```dart
activeSession: null,
finishedResult: null,
userAnswers: {},
elapsedSeconds: 0,
```

Expected: with the sentinel `copyWith`, these now clear nullable fields instead of preserving old values.

---

### Task 2: Prevent Repeated Navigation From Timer Ticks

**Files:**
- Modify: `lib/presentation/quiz/quiz_list_screen.dart`

**Interfaces:**
- Consumes: `QuizState.activeSession`.
- Produces: navigation only when a new active session appears.

- [ ] **Step 1: Add listenWhen to quizzes tab BlocConsumer**

In `lib/presentation/quiz/quiz_list_screen.dart`, update the `BlocConsumer<QuizBloc, QuizState>` in `_buildQuizzesTab`:

```dart
    return BlocConsumer<QuizBloc, QuizState>(
      listenWhen: (previous, current) {
        final previousSessionId = previous.activeSession?.sessionId;
        final currentSessionId = current.activeSession?.sessionId;
        return currentSessionId != null && currentSessionId != previousSessionId;
      },
      listener: (context, state) {
        if (state.activeSession != null) {
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
```

- [ ] **Step 2: Reason through timer behavior**

Timer tick changes `elapsedSeconds` only. `previous.activeSession?.sessionId` and `current.activeSession?.sessionId` are equal, so `listenWhen` returns `false`.

Expected: no additional `Navigator.push` calls during timer ticks.

---

### Task 3: Add Empty Question Guard

**Files:**
- Modify: `lib/presentation/quiz/quiz_play_screen.dart`

**Interfaces:**
- Consumes: `widget.session.questions`.
- Produces: safe UI when `questions.isEmpty`.

- [ ] **Step 1: Add guard before building BlocConsumer**

In `QuizPlayScreen.build`, after:

```dart
    final questions = widget.session.questions;
```

add:

```dart
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
```

- [ ] **Step 2: Confirm index access is protected**

Verify this line remains below the guard:

```dart
final currentQuestion = questions[_currentQuestionIndex];
```

Expected: no `RangeError` when the backend returns an empty question list.

---

### Task 4: Run Verification

**Files:**
- Verify: `lib/presentation/quiz/quiz_bloc.dart`
- Verify: `lib/presentation/quiz/quiz_list_screen.dart`
- Verify: `lib/presentation/quiz/quiz_play_screen.dart`

**Interfaces:**
- Consumes: completed Tasks 1-3.
- Produces: analyzer/test evidence and manual state-flow confidence.

- [ ] **Step 1: Run analyzer**

Run:

```powershell
flutter analyze
```

Expected: analyzer completes without new errors from quiz files. If it times out again after 120 seconds, record that timeout and continue to `flutter test`.

- [ ] **Step 2: Run tests**

Run:

```powershell
flutter test
```

Expected: existing tests pass, or failures are unrelated to the quiz changes and documented.

- [ ] **Step 3: Inspect diff**

Run:

```powershell
git diff -- lib\presentation\quiz\quiz_bloc.dart lib\presentation\quiz\quiz_list_screen.dart lib\presentation\quiz\quiz_play_screen.dart
```

Expected: diff only contains the nullable-clear `copyWith`, `listenWhen`, stale error clear, and empty-question guard.

- [ ] **Step 4: Manual behavior checklist**

Use the app and verify:

- Start quiz opens one `QuizPlayScreen`.
- Waiting three seconds updates the timer without stacking screens.
- Exit returns to quiz list and does not reopen quiz.
- Submit navigates to one `QuizResultScreen`.
- Time limit auto-submit fires once.

---

## Self-Review

- Spec coverage: Task 1 covers nullable cleanup; Task 2 covers repeated navigation; Task 3 covers empty questions; Task 4 covers verification.
- Placeholder scan: no placeholder patterns remain.
- Type consistency: `activeSession` casts to `QuizSession?`, `finishedResult` casts to `QuizResult?`, and `error` casts to `String?`, matching `QuizState` fields.
