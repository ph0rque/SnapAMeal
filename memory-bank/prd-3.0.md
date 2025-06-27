# PRD 3.0 – Polish and Reliability

## Introduction / Overview

Phase 3.0 focuses on hardening the Investor Demo Enhancement Platform delivered in Phase 2.1.  The objective is to eliminate all build-time warnings, bolster demo stability, and guarantee that demo data is reliably provisioned and maintained in Firebase.  No new user-facing AI capabilities or personas will be introduced; the emphasis is on polish, robustness, and confidence during live investor demonstrations.

## Goals

1. **Zero Build Warnings** – Achieve clean `flutter build` output for both Android and iOS.
2. **Credential Robustness** – Ensure demo-login works 100 % of the time by auto-provisioning or restoring missing credentials.
3. **Data Integrity** – Validate that seeded demo data exists, is internally consistent, and stored in Firebase before each demo session.
4. **Android Unblock** – Replace or conditionally compile the deprecated `screenshot_callback` package so Android builds succeed out-of-the-box.
5. **Logging & Maintainability** – Introduce a unified logger wrapper and lightweight dependency-injection (DI) pattern to simplify testing and future maintenance.

## User Stories

### Demo Presenter
- *As a presenter*, I want the app to build without warnings on both platforms so I can install it quickly before a meeting.
- *As a presenter*, I want demo logins to always succeed so that I'm never embarrassed in front of investors.
- *As a presenter*, I want assurance that demo data appears exactly as scripted so the narrative flows smoothly.

### Developer
- *As a developer*, I need a single command to verify data integrity so that regression bugs are caught early.
- *As a developer*, I need a clean build to maintain professional code standards and speed up CI/CD.

## Functional Requirements

### 1. Build Clean-Up
FR-1.1  Remove or replace the `screenshot_callback` dependency.
FR-1.2  Resolve all analyzer warnings & infos (target: **0 warnings**, **0 infos**).
FR-1.3  Update `analysis_options.yaml` and CI scripts to fail on new warnings.

### 2. Credential Provisioning
FR-2.1  Add logic in **AuthService** to detect missing demo accounts and auto-create them (email/password or anonymous UID aliasing).
FR-2.2  Ensure demo account UIDs are deterministic (`demo_alice`, `demo_bob`, `demo_charlie`).
FR-2.3  Cache the last successful demo login locally to speed up repeat launches.

### 3. Data Integrity Validator
FR-3.1  Implement `DemoDataValidator.validate()` that checks:
  • Reciprocal friendships
  • Group memberships consistency
  • Meal/Fast logs point to existing userIDs
  • Expected doc counts per collection
FR-3.2  Integrate validator into startup sequence; show a blocking error dialog if the dataset is corrupted.
FR-3.3  Provide a CLI flag (`scripts/seed_demo_data.dart --validate`) to run validator in CI or locally.

### 4. Deterministic Reset Hashes
FR-4.1  `DemoResetService` will compute a per-collection hash (docCount + latestUpdatedAt) to compare pre- and post-reset states.
FR-4.2  Reset operation must complete in < 10 s and verify hash equality afterward.

### 5. Logging & Dependency Injection
FR-5.1  Add a `Logger` wrapper with configurable log levels (DEBUG, INFO, ERROR).
FR-5.2  Replace `debugPrint` usages with the new logger.
FR-5.3  Introduce a DI container (`get_it` or `riverpod`) for core services (AuthService, DemoDataService, Logger).
FR-5.4  Update unit tests to use mock instances via DI.

## Non-Goals / Out of Scope
- Adding new AI capabilities, personas, or investor-tour overlay.
- Implementing Firebase Analytics, BigQuery exports, or offline demo cache.
- Expanding CI beyond analyzer/build checks.

## Success Metrics
| Metric | Target |
|--------|--------|
| Build warnings (Android/iOS) | **0** |
| Demo-login failure rate | **0 %** across 100 manual attempts |
| Validator pass rate | **100 %** on seeded datasets |
| Android build success (CI) | **100 %** |
| Demo reset time | ≤ 10 s including hash verification |

## Timeline & Milestones (2-Week Sprint)
| Week | Deliverable |
|------|-------------|
| **W1-Mon** | Replace `screenshot_callback`; clean analyzer warnings |
| **W1-Wed** | Credential auto-provisioning complete |
| **W1-Fri** | DemoDataValidator implementation + unit tests |
| **W2-Mon** | Deterministic hash reset flow |
| **W2-Wed** | Logger wrapper & DI refactor |
| **W2-Thu** | Full regression testing (iOS & Android) |
| **W2-Fri** | Sprint review & sign-off (stakeholder: Product Owner) |

## Stakeholders
- **Product Owner / Approver**: You (solo)
- **Engineering**: 1–2 Flutter devs

## Risks & Mitigations
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|-----------|
| Package replacement causes unforeseen iOS issues | Medium | Medium | Run early iOS smoke test after swap |
| Auto-provisioning collides with existing prod accounts | Low | High | Prefix demo emails with `demo_` and isolate in Firestore rules |
| DI refactor introduces regressions | Medium | Medium | Incremental migration + unit tests |

## Open Questions
1. Should validator run silently in production builds or only in dev/demo mode?
2. Do we want a visual progress indicator during reset validation, or is blocking dialog acceptable?

---

**Status:** Draft – awaiting approval. 