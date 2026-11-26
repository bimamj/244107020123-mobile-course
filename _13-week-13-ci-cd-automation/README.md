# Week 13 — CI/CD & Automation (`campus_notify`)

## 1. CI/CD Workflow Configuration

The GitHub Actions workflow is configured at the repository root in [`.github/workflows/flutter-ci.yml`](../.github/workflows/flutter-ci.yml).

### Triggers & Safeguards
- **Triggers**: `push` to `main`, `pull_request` to `main`, and `workflow_dispatch` (manual trigger).
- **Permissions**: Least-privilege `contents: read`.
- **Concurrency**: Cancels superseded in-progress runs for the same workflow and ref (`${{ github.workflow }}-${{ github.ref }}`).

### Pipeline Steps (`test-and-build` on `ubuntu-latest`)
1. **Checkout repository** (`actions/checkout@v4`)
2. **Set up Java 17** (`actions/setup-java@v4`, Temurin distribution, Gradle cache enabled)
3. **Set up Flutter** (`subosito/flutter-action@v2`, `stable` channel, cache enabled)
4. **Install dependencies**: `flutter pub get`
5. **Check formatting**: `dart format --output=none --set-exit-if-changed .`
6. **Run static analysis**: `flutter analyze --fatal-infos`
7. **Run tests with coverage**: `flutter test --coverage`
8. **Build release APK**: `flutter build apk --release`
9. **Build release AAB**: `flutter build appbundle --release`
10. **Upload artifacts** (`actions/upload-artifact@v4`):
    - `campus-notify-apk`: `build/app/outputs/flutter-apk/app-release.apk`
    - `campus-notify-aab`: `build/app/outputs/bundle/release/app-release.aab`
    - `campus-notify-coverage`: `coverage/lcov.info`

---

## 2. Next Version Plan

- **Current version** (in [`pubspec.yaml`](../_12-week-12-testing-quality-assurance/campus_notify/pubspec.yaml)): `1.0.0+1` (`versionName = 1.0.0`, `versionCode = 1`).
- **Next planned version**: `1.0.1+2` (patch release incorporating CI/CD automation, Dart formatting standardization, and lint fixes) or `1.1.0+2` for the next feature milestone.
- **Versioning rule**: Follow Semantic Versioning (`MAJOR.MINOR.PATCH+BUILD_NUMBER`) and increment `+BUILD_NUMBER` (`versionCode`) on every release build uploaded to Google Play.

---

## 3. Checks Performed & Verification Evidence

All CI checks were verified locally inside `_12-week-12-testing-quality-assurance/campus_notify`:

| Check | Command | Result |
| :--- | :--- | :--- |
| **Formatting** | `dart format --output=none --set-exit-if-changed lib test integration_test` | Passed (`Formatted 67 files (0 changed) in 0.28 seconds`) |
| **Static Analysis** | `flutter analyze --fatal-infos` | Passed (`No issues found! (ran in 3.2s)`) |
| **Unit & Widget Tests** | `flutter test --coverage` | Passed (`00:06 +38: All tests passed!`, `coverage/lcov.info` generated) |
| **Release APK Build** | `flutter build apk --release` | Passed (`build\app\outputs\flutter-apk\app-release.apk`, `56.8MB`) |
| **Release AAB Build** | `flutter build appbundle --release` | Passed (`build\app\outputs\bundle\release\app-release.aab`, `56.0MB`) |

### Git & GitHub Actions Run Evidence
- **Repository**: `https://github.com/bimamj/244107020123-mobile-course`
- **Branch**: `main`
- **Commit / Actions Run**:
  - Push these changes to `main` (or open a pull request targeting `main`) to trigger `Flutter CI` on GitHub Actions.
  - Record the resulting commit SHA and GitHub Actions run URL here after pushing:
    - Commit SHA: `<pending push>`
    - Workflow Run URL: `https://github.com/bimamj/244107020123-mobile-course/actions`

---

## 4. Remaining Security Risks

1. **Release build signed with debug key**: [`android/app/build.gradle.kts`](../_12-week-12-testing-quality-assurance/campus_notify/android/app/build.gradle.kts#L38) currently sets `signingConfig = signingConfigs.getByName("debug")` for `release` builds. Debug-signed artifacts cannot be published to Google Play and must be replaced with a dedicated upload keystore (`key.properties` + GitHub Actions Secrets).
2. **`google-services.json` tracked in Git**: [`android/app/google-services.json`](../_12-week-12-testing-quality-assurance/campus_notify/android/app/google-services.json) is committed to the repository, exposing Firebase project identifiers and API key metadata in Git history.
3. **Placeholder `applicationId`**: `android/app/build.gradle.kts` still uses `com.example.campus_notify`, which must be updated to a unique production application ID before distribution.
4. **No automated integration test execution in CI**: `integration_test/app_test.dart` is not executed on an Android emulator in the `ubuntu-latest` workflow, leaving end-to-end device flows unverified in CI.
5. **No dependency or secret scanning step**: The pipeline does not yet run automated secret scanning or dependency vulnerability checks.

---

## 5. Reflection

### What problem was detected automatically before changes were merged?
- **Formatting inconsistencies across 51 files**: Running `dart format --output=none --set-exit-if-changed` immediately flagged 51 out of 67 Dart files in `lib/`, `test/`, and `integration_test/` that did not conform to `dart format`.
- **Lint violation exposed after formatting**: Once `dart format` reformatted the code, `flutter analyze --fatal-infos` detected a `curly_braces_in_flow_control_structures` info-level issue at `test/features/notes/notes_usecases_test.dart:17:7`, which was fixed before proceeding.
- **Misconfigured workflow root & missing build/artifact steps**: The initial `.github/workflows/flutter-ci.yml` lacked `working-directory: _12-week-12-testing-quality-assurance/campus_notify`, Java 17 setup, release APK/AAB builds, and `actions/upload-artifact@v4`.

### What information would help you investigate a failed build?
- The exact failing step name, exit code, and full console output from the GitHub Actions job log.
- The triggering commit SHA, branch/PR reference, and diff since the last passing run.
- Environment and dependency versions (`flutter --version`, `dart --version`, `java -version`, Gradle/AGP versions, and `pubspec.lock`).
- Gradle `--stacktrace` / `--info` logs for Android build errors, and test/coverage reports (`coverage/lcov.info`) for test failures.

### What still needs approval or manual review before a release?
- **Release signing & secrets setup**: Generating a production upload keystore, storing it in GitHub Secrets, and updating `build.gradle.kts` to use a proper `release` signing config.
- **Store metadata & identifiers**: Replacing `com.example.campus_notify` with the final `applicationId` and bumping `version` in `pubspec.yaml` (`1.0.1+2` or `1.1.0+2`).
- **Manual QA on physical devices**: Installing and smoke-testing the built `app-release.apk` / `app-release.aab` on real Android hardware (including FCM push notifications and end-to-end flows in `integration_test/app_test.dart`).
- **PR & Play Console approval**: Peer code review on `main` and manual promotion through Google Play Console testing tracks before public rollout.
