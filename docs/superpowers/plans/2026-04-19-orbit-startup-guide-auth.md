# Orbit Startup Guide + Authorization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a cleaner first-run flow with local authorization, a reusable guide screen, and a more polished handoff into onboarding and chat.

**Architecture:** Persist auth and guide state in the existing Hive-backed user profile, route all startup decisions through `HomeScreen`, and keep guide access available from the main workspace after onboarding. Preserve current onboarding scoring and chat behavior.

**Tech Stack:** Flutter, Provider, Hive, widget tests

---

### Task 1: Persist startup gate state

**Files:**
- Modify: `lib/hive/user_model.dart`
- Modify: `lib/hive/user_model.g.dart`
- Modify: `lib/providers/user_profile_provider.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write the failing persistence and route tests**

Add tests that describe unauthorized users seeing the auth screen and authorized-but-guide-incomplete users seeing the guide.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because the current startup flow knows only onboarding and chat.

- [ ] **Step 3: Add append-only Hive fields and provider state**

Persist authorization + guide completion in the profile model and expose getters/actions from `UserProfileProvider`.

- [ ] **Step 4: Run test to verify the new state compiles and passes targeted checks**

Run: `flutter test test/widget_test.dart`
Expected: The new route tests still fail until UI routing is wired, but model/provider errors are gone.

### Task 2: Add authorization + guide screens

**Files:**
- Create: `lib/screens/authorization_screen.dart`
- Create: `lib/screens/startup_guide_screen.dart`
- Modify: `lib/screens/home_screen.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write failing widget tests for auth and guide progression**

Describe: auth -> guide -> onboarding progression.

- [ ] **Step 2: Run targeted widget tests**

Run: `flutter test test/widget_test.dart`
Expected: FAIL because these screens and transitions do not exist yet.

- [ ] **Step 3: Implement minimal screens and route logic**

Use `HomeScreen` as the startup switchboard and keep copy honest about local-only access.

- [ ] **Step 4: Re-run widget tests**

Run: `flutter test test/widget_test.dart`
Expected: PASS for the new route path tests.

### Task 3: Refresh onboarding and workspace affordances

**Files:**
- Modify: `lib/screens/onboarding_screen.dart`
- Modify: `lib/screens/chat_screen.dart`
- Modify: `lib/widgets/chat/chat_header.dart`
- Modify: `lib/widgets/chat/chat_empty_state.dart`
- Modify: `lib/themes/my_theme.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Add failing assertions for guide reopen and improved startup handoff**

Extend widget coverage so chat exposes a guide affordance.

- [ ] **Step 2: Run the focused widget suite**

Run: `flutter test test/widget_test.dart`
Expected: FAIL until the guide affordance and refreshed routing are wired.

- [ ] **Step 3: Implement UI refresh**

Improve hierarchy, tighten copy, add guide reopen affordance, and preserve existing chat entry behavior.

- [ ] **Step 4: Re-run widget tests**

Run: `flutter test test/widget_test.dart`
Expected: PASS.

### Task 4: Full verification

**Files:**
- Verify changed files only

- [ ] **Step 1: Run static verification**

Run: `flutter analyze`
Expected: 0 issues.

- [ ] **Step 2: Run widget / regression tests**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 3: If Hive schema changed, regenerate adapters and re-run verification**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: generated files updated, followed by green analyze/test runs.
