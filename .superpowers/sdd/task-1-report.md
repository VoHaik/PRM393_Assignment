# Task 1 Report: Make QuizState Nullable Fields Clearable

## Scope
- Updated `lib/presentation/quiz/quiz_bloc.dart` only.

## What Changed
- Added a top-level `_sentinel` constant above `QuizState`.
- Replaced `QuizState.copyWith(...)` with a sentinel-based implementation so `activeSession`, `finishedResult`, and `error` can be explicitly cleared with `null`.
- Updated `_onStartQuizSessionRequested` to clear stale `finishedResult` and `error` when a new quiz session starts.

## Verification
- Ran the brief's `rg` inspection against `lib\presentation\quiz\quiz_bloc.dart` and confirmed the expected clear paths are present.
- Attempted `flutter analyze lib\presentation\quiz\quiz_bloc.dart`; it timed out after 300 seconds in this environment.

## Notes
- The submit and clear paths already pass `activeSession: null` and `finishedResult: null`; with the new `copyWith`, those calls now clear the nullable fields instead of preserving prior values.
