## Files Created & Modified

### Created
- `test/features/notes/notes_page_test.dart` — Widget tests for `NotesPage` and `AddNoteDialog` (initial state, loading, error/retry, add note, invalid input, repository failure).
- `integration_test/app_test.dart` — End-to-end integration test covering Login -> Home -> Notes -> Add & Search Note.

### Modified
- `pubspec.yaml` — Added `integration_test: sdk: flutter` under `dev_dependencies`.
- `lib/features/notes/presentation/pages/notes_page.dart` — Added `Key('add_note_fab')` to the add note FAB.
- `lib/features/notes/presentation/widgets/add_note_dialog.dart` — Added `Key`s (`note_title_field`, `note_body_field`, `cancel_note_button`, `save_note_button`).
- `lib/features/auth/presentation/pages/login_page.dart` — Added `Key`s (`login_email_field`, `login_password_field`, `login_submit_button`).
- `lib/features/announcements/presentation/pages/home_page.dart` — Added `Key('home_notes_button')` to the Notes navigation button.
- `test/features/notes/notes_usecases_test.dart` — Added `failNext` handling in `FakeNoteRepository.addNote`, `maxTitleLength` boundary tests, and save-failure propagation test.
- `lib/features/chat_assistant/domain/services/sensitive_data_filter.dart` — Fixed `_phonePattern` to support 3-4 digit segments, applied `_creditCardPattern` before `_phonePattern` in `sanitizePii`, and removed unnecessary regex escape (`\-` → `-`).
- `lib/features/announcements/data/repositories/announcement_repository_impl.dart` — Converted constructor parameters to initializing formals (`this._remote`, `this._cacheTtl`).
- `lib/features/chat_assistant/data/datasources/chat_local_data_source.dart` — Removed redundant `package:sqflite/sqflite.dart` import.
- `lib/features/chat_assistant/data/datasources/chat_remote_data_source.dart` — Used set literal with null-aware element (`?_resolvedModel`).
- `lib/features/chat_assistant/domain/usecases/send_chat_message.dart` — Converted constructor parameters to initializing formals (`this._repository`, `this._filter`).
- `lib/features/chat_assistant/presentation/pages/chat_page.dart`, `chat_bubble.dart`, `chat_input_bar.dart` — Replaced deprecated `.withOpacity()` with `.withValues(alpha: ...)`, guarded `ctx.mounted` before `Navigator.pop(ctx)`, and replaced `__` with `_`.
- `README.md` — Documented test scenarios, coverage, analysis results, integration test blocker, reflection, and file changes.
