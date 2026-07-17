# Quiz Freeze Fix Design

## Goal

Fix the quiz flow so starting a quiz opens exactly one play screen, the timer updates normally, and exiting or submitting clears the active quiz session.

## Context

The app follows Clean Architecture with BLoC in the presentation layer. The quiz flow is:

`QuizListScreen -> QuizPlayScreen -> QuizResultScreen`

Relevant files:

- `lib/presentation/quiz/quiz_bloc.dart`
- `lib/presentation/quiz/quiz_list_screen.dart`
- `lib/presentation/quiz/quiz_play_screen.dart`

The data and domain layers do not need changes for this bug.

## Root Causes

`QuizState.copyWith` cannot clear nullable fields. It currently uses `activeSession: activeSession ?? this.activeSession`, so calls such as `activeSession: null` keep the old session instead of clearing it.

`QuizListScreen` navigates whenever `state.activeSession != null`. Because the timer updates state every second while `activeSession` remains non-null, the listener can push `QuizPlayScreen` repeatedly.

`QuizPlayScreen` assumes `session.questions` has at least one item. If the backend returns an empty question list, the screen can crash or appear stuck.

## Selected Approach

Use Option A: minimal fix.

- Update `QuizState.copyWith` to allow nullable fields to be explicitly cleared.
- Add `listenWhen` in `QuizListScreen` so navigation only happens when a quiz session first becomes active or changes to a different session.
- Add an empty-question guard in `QuizPlayScreen`.

This avoids broader refactoring, new navigation events, or changes to repository/API/domain contracts.

## Expected Behavior

Starting a quiz:

- Sets `activeSession`.
- Pushes exactly one `QuizPlayScreen`.
- Starts one timer.

Timer tick:

- Updates `elapsedSeconds`.
- Does not push another play screen.

Exit quiz:

- Cancels timer.
- Clears `activeSession`, `finishedResult`, answers, and elapsed time.
- Returns to quiz list without being pushed back into the quiz.

Submit quiz:

- Cancels timer.
- Submits answers once.
- Clears `activeSession`.
- Navigates to result screen once.

Empty session:

- Shows an error state instead of indexing into an empty question list.

## Validation

Run static analysis:

```powershell
flutter analyze
```

If the analyzer times out in this workspace, run a narrower check after edits by building or running available tests:

```powershell
flutter test
```

Manual verification criteria:

- Tap "Bắt đầu làm bài" once and confirm only one quiz screen is opened.
- Wait at least three seconds and confirm timer changes without pushing screens.
- Tap exit and confirm the app stays on the quiz list.
- Start again, answer questions, submit, and confirm one result screen opens.
