## Relevant Files

- `pubspec.yaml` – Remove/replace `screenshot_callback` dependency.
- `analysis_options.yaml` – Set analyzer rules to treat warnings/info as errors.
- `lib/services/auth_service.dart` – Auto-provision & cache demo credentials.
- `lib/services/demo_data_service.dart` – Extended integrity validation helpers.
- `lib/services/demo_reset_service.dart` – Add deterministic hash logic post-reset.
- `lib/utils/logger.dart` – New unified logging wrapper.
- `lib/di/service_locator.dart` – New DI container setup (e.g., get_it).
- `integration_test/demo_login_flow_test.dart` – Integration test ensuring demo login reliability.
- `test/demo_data_validator_test.dart` – Unit tests for data validator.
- `scripts/seed_demo_data.dart` – Add `--validate` flag and invoke validator.

### Notes

- Place unit tests next to their source files when practical.
- Use `flutter test` for unit tests and `flutter drive` / `integration_test` for integration.
- CI should call both analyzer and test suites.

## Tasks

- [x] 1.0 Clean Build Environment (Zero Warnings)
  - [x] 1.1 Replace or conditionally compile out the `screenshot_callback` package.
  - [x] 1.2 Remove any lingering imports/usages of the old package.
  - [x] 1.3 Run `flutter analyze` and fix all warnings & infos across the codebase.
  - [x] 1.4 Tighten `analysis_options.yaml` to fail the build on new warnings.
  - [x] 1.5 Update CI pipeline (GitHub Action) to run analyzer and unit tests on PRs.

- [ ] 2.0 Credential Provisioning & Robust Demo Login
  - [ ] 2.1 Design deterministic UID/email scheme for demo accounts (`demo_alice`, etc.).
  - [ ] 2.2 Extend `AuthService` to check for missing demo accounts at login.
  - [ ] 2.3 Implement auto-creation logic using Firebase Auth Admin SDK (Cloud Function) or client-side email/password creation guarded by rules.
  - [ ] 2.4 Cache last successful login locally (SharedPreferences / secure storage).
  - [ ] 2.5 Create `integration_test/demo_login_flow_test.dart` to verify login success for all personas.

- [ ] 3.0 Demo Data Integrity Validator
  - [ ] 3.1 Define validation rules (friend reciprocity, group membership, doc counts).
  - [ ] 3.2 Implement `DemoDataValidator` inside `demo_data_service.dart`.
  - [ ] 3.3 Add `--validate` CLI flag to `scripts/seed_demo_data.dart` that calls the validator.
  - [ ] 3.4 Write unit tests (`test/demo_data_validator_test.dart`).
  - [ ] 3.5 Invoke validator automatically on app startup in demo mode; display blocking error dialog if invalid.

- [ ] 4.0 Deterministic Demo Reset Hashes
  - [ ] 4.1 Design lightweight hash algorithm (docCount + latestUpdatedAt) per collection.
  - [ ] 4.2 Implement pre-seed baseline hash capture.
  - [ ] 4.3 Extend `DemoResetService` to recompute hashes after reset and compare.
  - [ ] 4.4 Show success/failure snackbar based on hash comparison.
  - [ ] 4.5 Ensure reset + verification completes in ≤ 10 s (optimize with batched reads).

- [ ] 5.0 Logging Framework & Dependency Injection Setup
  - [ ] 5.1 Create `lib/utils/logger.dart` with levels DEBUG/INFO/ERROR.
  - [ ] 5.2 Refactor existing `debugPrint` calls to use new logger (search & replace).
  - [ ] 5.3 Introduce `lib/di/service_locator.dart` using `get_it` (or Riverpod provider container).
  - [ ] 5.4 Register core services (AuthService, DemoDataService, Logger) in DI.
  - [ ] 5.5 Update unit tests to inject mock services via DI. 