# Orbit Startup Guide + Authorization Design

## Summary

Orbit should feel like one coherent product from the first screen. The startup path will become:

1. Authorization
2. Guide
3. Onboarding
4. Chat workspace

The guide also remains reachable later from the app so it is not lost after first run.

## Design direction

- Brand-first first screen with a calm full-canvas background.
- Utility copy over marketing copy.
- One dominant action per stage.
- Fewer card-like containers and stronger section structure.
- Reuse the existing teal/blue palette, but tighten contrast and spacing so the app reads as intentional instead of piecemeal.

## Functional design

### Authorization screen

- Collect school email and optional access code.
- Explain local-only storage and whether an access code is enforced.
- Persist auth state in the profile model so the app can reopen directly into later stages.

### Guide screen

- Introduce four things:
  - how Orbit supports planning, writing, and wellbeing
  - what signals power personalization
  - what connected data sources do
  - how users can reopen tools and settings later
- Provide a single continue action into onboarding.
- Provide a smaller skip action only if needed.

### Onboarding refresh

- Keep current question set and label ranking logic.
- Group identity fields and questionnaire into more readable sections.
- Improve progress treatment and preview language.

### Workspace refinement

- Add a guide affordance to the primary workspace header.
- Make empty-state orientation feel more like a command center than a blank chat.

## Persistence

- `UserModel` gains durable fields for:
  - authorization state
  - authorized-at / method metadata if useful
  - guide completion state
- `UserProfileProvider` becomes the single source of truth for startup-gate decisions.

## Testing

- Protect route gating through widget tests.
- Protect provider persistence through provider/unit tests where feasible.
