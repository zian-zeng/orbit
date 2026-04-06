# Recommendation + Skill Router Plan

## RALPLAN-DR Summary

### Principles

1. Keep v1 deterministic and inspectable.
2. Fit the existing Flutter `provider` + `hive` architecture before adding new layers.
3. Separate recommendation logic from Gemini message dispatch.
4. Capture structured signals now so a smarter recommender can be added later.
5. Require teammate review through a PR before any merge to `main`.

### Decision Drivers

1. The repo currently has static prompt chips and no label or recommendation schema.
2. The app is small, so a heavy agent platform or learned recommender would add more complexity than value in v1.
3. The feature needs to be understandable, testable, and reviewable by a collaborator.

### Viable Options

#### Option A: Deterministic label-to-prompt router MVP

Pros:
- Smallest change set.
- Easy to test with plain Dart/widget tests.
- Clear upgrade path toward richer recommendation signals later.

Cons:
- Recommendations will be rule-limited at first.
- Quality depends on the initial label taxonomy.

#### Option B: Hybrid router with Gemini label classification on every draft

Pros:
- More flexible intent detection.
- Less manual rule writing.

Cons:
- Harder to verify and tune.
- Adds latency, cost, and failure modes before the app captures enough feedback data.

#### Option C: Full recommendation/workflow engine with composable skills

Pros:
- Strongest long-term extensibility.
- Could support richer multi-step coaching flows.

Cons:
- Over-scoped for the current repo.
- Requires abstractions, telemetry, and tests the app does not have yet.

### Recommended Direction

Choose Option A for v1, but design the router boundary so Option B can be added later behind the same interfaces.

### Architect review synthesis

- Use a pure `PromptRouter` service as the default boundary. Do not introduce a long-lived `RecommendationProvider` unless debounced cross-widget synchronization actually requires it during implementation.
- Keep transient draft-routing state close to the composer UI. `ChatProvider` should continue to own send/persist/model dispatch, not per-keystroke recommendation state.
- Split rollout into two slices:
  - Slice 1: dynamic recommendations, manual label override, prompt prefilling, and tests
  - Slice 2: durable Hive metadata for selected label and chosen template once the UI flow is stable
- Persist only stable catalog IDs, not ephemeral scores or generated identifiers. If a recommendation is stored, it should reference a deterministic template or label key that can be replayed later.

## Implementation Plan

### Architectural notes to preserve in implementation

- Keep the routing layer pure and side-effect free; it should evaluate context and return recommendations, not write Hive data or call Gemini directly.
- Add a narrow `RoutingContext` model so `ChatProvider`, UI widgets, and future classifiers do not exchange loose maps or duplicated heuristics.
- Avoid coupling Hive entity classes to UI-only display fields; persist stable routing metadata and derive display copy in the router/template layer.
- Treat current composer text and selected label as transient app state, not `ChatProvider` state. The current `BottomChatField` owns draft text, so v1 should use a small local controller or narrowly scoped composer-routing state rather than pushing per-keystroke updates into `ChatProvider`.
- Use append-only Hive field IDs with safe defaults on new fields. Do not repurpose existing field numbers, and prefer optional persisted metadata over eager migrations that force old history to be rewritten.
- If Hive models change, include regenerated adapters and an explicit `build_runner` step in the implementation checklist.

### Phase 1: Define the routing vocabulary

Goal: introduce a clear label and template catalog without changing the app flow yet.

Likely touchpoints:
- `lib/constants/constants.dart`
- `lib/models/`
- `lib/providers/`
- `lib/services/`

Work:
- Define a small label taxonomy such as `planning`, `writing`, `study_help`, `summarization`, `image_analysis`, and `wellbeing_checkin`.
- Create a recommendation model that includes:
  - `label`
  - `title`
  - `description`
  - `promptTemplate`
  - `skillId` or `workflowType`
  - `score`
  - `reason`
- Create an app-local template catalog so “skills” are explicit and reusable even if they are only prompt templates in v1.
- Add a `RoutingContext` model with only the signals the router needs in v1:
  - `draftText`
  - `selectedLabel`
  - `hasImages`
  - `recentLabels`
  - `preferredLabels`

### Phase 2: Add a recommendation boundary

Goal: stop baking suggestion logic into constants and UI widgets.

Likely touchpoints:
- `lib/providers/chat_provider.dart`
- new files under `lib/providers/` or `lib/services/`
- `lib/widgets/bottom_chat_field.dart`

Work:
- Add a pure `PromptRouter` service that:
  - infers candidate labels from profile, recent chat history, and current draft text
  - ranks recommendations deterministically
  - returns a small list of recommended prompts/workflows
- Keep `ChatProvider` responsible for sending content to Gemini.
- Add a clean handoff method so UI can ask for recommendations without knowing routing details.
- Wire `BottomChatField` to publish draft-text and image-attachment changes into a lightweight local routing controller so recommendations can respond before a message is sent.
- Keep the router API narrow, for example `List<Recommendation> recommend(RoutingContext context)`.
- Add a short debounce during typing if recommendation recomputation becomes noisy in practice.

Recommended scoring inputs for v1:
- explicit user-selected label
- current draft text keyword/rule match
- whether images are attached
- recent chat history labels
- optional preferred labels stored in profile/settings

Fallback rule:
- If the router cannot infer a strong recommendation, return a stable default set rather than no suggestions.

### Phase 3: Ship the UI flow before schema work

Goal: prove the user-facing routing experience before expanding Hive models.

Likely touchpoints:
- `lib/widgets/chat/chat_empty_state.dart`
- `lib/screens/chat_screen.dart`
- `lib/widgets/bottom_chat_field.dart`
- new router files from earlier phases

Work:
- Replace `Constants.starterPrompts` rendering with recommendations from the router.
- Add a lightweight manual label override control.
- Show a short reason for each recommendation, for example “Based on your draft” or “Because you attached an image”.
- Treat v1 “skills” as app-local prompt/template workflows, not external runtimes.
- When the user taps a recommendation, prefill the composer with the routed template instead of auto-sending.
- If there is no useful routing signal, fall back to a stable default recommendation set rather than an empty UI.
- Validate that standard text chat and image chat still work with the new entry flow.

### Phase 4: Extend persistence for labels and feedback

Goal: store enough structure to improve recommendations later.

Likely touchpoints:
- `lib/hive/user_model.dart`
- `lib/hive/chat_history.dart`
- generated `*.g.dart` files
- `lib/providers/user_profile_provider.dart`
- `lib/providers/chat_provider.dart`

Work:
- Extend `UserModel` with lightweight personalization data such as preferred labels or pinned goals.
- Extend `ChatHistory` with fields such as:
  - `selectedLabel`
  - `recommendedSkillId`
  - `templateId`
- Persist only durable routing metadata needed for replay and analytics. Do not persist ephemeral scores, ranking positions, or display-only reason strings unless a real downstream use appears.
- Save the routed label/skill alongside each prompt so future recommendation logic can learn from actual usage.
- Use append-only Hive field IDs with safe defaults for all new persisted fields.
- Make persisted keys come from a stable in-app catalog so older records remain interpretable.

### Phase 5: Add tests before behavior grows

Goal: prevent the feature from becoming a pile of UI-only heuristics.

Likely touchpoints:
- `test/widget_test.dart`
- new tests under `test/providers/` and `test/widgets/`

Work:
- Add pure Dart tests for label inference and ranking rules.
- Add widget tests for:
  - empty-state recommendations rendering
  - label override behavior
  - prefilled prompt flow
- Add persistence tests for upgraded Hive models once Phase 4 begins.
- Add regression coverage that old history records and existing settings still load when new Hive fields are absent.

### Phase 6: Ship through branch + PR review

Goal: make the change reviewable by a collaborator before merge.

Work:
- Keep the implementation on a feature branch.
- Push the branch and open a draft PR against `main`.
- Ask the collaborator to review:
  - label taxonomy
  - router rules
  - persisted schema changes
  - UX copy for recommendations and labels
- Merge only after review comments are addressed and verification passes.

## ADR

### Decision

Implement a deterministic recommendation and prompt-routing MVP with a pure router boundary, local transient composer-routing state, recommendation-driven entry UI, and delayed Hive persistence until the UI flow is validated.

### Drivers

- The current repo has no intent metadata or router abstraction.
- The app needs a shippable MVP more than a speculative recommendation engine.
- Deterministic routing is easier to review, explain, and test.

### Alternatives Considered

1. Gemini-driven label classification first.
   Rejected for v1 because it adds latency, prompt-tuning complexity, and weaker testability.
2. Full skill engine with multi-step workflows.
   Rejected for v1 because it is broader than the current app architecture and team need.

### Why Chosen

This approach adds real recommendation behavior, not just renamed starter prompts, while preserving a clean upgrade path to stronger personalization later and reducing migration risk in the first implementation slice.

### Consequences

- Short-term recommendation quality will be bounded by rules and taxonomy quality.
- The codebase gains a clearer routing seam, which is good architectural debt to take on now.
- Hive schema changes remain necessary, but only after the user-facing interaction is stable.

### Follow-ups

- Add user feedback loops such as thumbs-up/down or “was this helpful”.
- Consider optional Gemini-based classification behind the same router interface.
- Re-rank recommendations using real usage history once enough data exists.

## PR Workflow

1. Implement on a dedicated feature branch, not on `main`.
2. Commit in small reviewable slices, starting with router models/tests, then UI flow, then persistence if the first slice is approved.
3. Push the branch to `origin`.
4. Open a draft PR targeting `main` with:
   - feature summary
   - schema changes
   - screenshots or screen recordings
   - verification notes
   - known follow-ups
5. Request teammate review on the draft PR before marking it ready or merging.
6. Address feedback on the same branch, then merge after approval.

Suggested branch naming for implementation:
- `codex/recommendation-skill-router`

Suggested PR title:
- `Add label-driven recommendation and prompt routing MVP`

## Agent Roster & Staffing

Available agent types for follow-up:
- `planner`
- `architect`
- `critic`
- `executor`
- `test-engineer`
- `verifier`
- `designer`

### Ralph path

Use when one agent should implement the feature sequentially with tight verification.

Suggested lanes:
- `planner` medium: refine file-by-file task order from this plan
- `executor` high: implement models, router, provider wiring, and UI
- `test-engineer` medium: add pure Dart and widget coverage
- `verifier` high: confirm persistence, rendering, and routing behavior

### Team path

Use when parallel work is worth the overhead.

Suggested staffing:
- lane 1: `executor` high for data models and routing layer
- lane 2: `executor` medium for UI integration in chat entry surfaces
- lane 3: `test-engineer` medium for routing and widget tests
- lane 4: `verifier` high for end-to-end evidence and regression checks

Suggested team launch shape:
- `omx team` or `$team` with separate tasks for router core, UI integration, tests, and verification
- If persistence is split into a second slice, treat it as a separate implementation task in the team plan rather than mixing it into the first UI PR.

## Verification Path

Implementation should not be considered done until all of the following are true:

1. Recommendation chips are generated from router output, not `Constants.starterPrompts`.
2. A label can be inferred or manually chosen and is reflected in the routed prompt/workflow.
3. In slice 1, routed metadata is visible in memory and reflected in the composed prompt flow; in slice 2, stable label/template metadata is stored with chat history.
4. Widget tests cover empty-state recommendation rendering and label override behavior.
5. Routing tests cover representative labels and edge cases.
6. A PR exists for teammate review before merge to `main`.

Planned command checks once Flutter is available:

```bash
flutter pub get
dart format lib test
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Current environment note:
- `flutter` is not installed in the current shell, so these checks are part of the implementation verification plan rather than checks already executed here.
