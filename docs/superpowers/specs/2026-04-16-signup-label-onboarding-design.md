# Signup Label Onboarding Design

## Goal

Convert first-run profile setup into a lightweight onboarding flow that asks intent questions, scores the app's six support labels, and stores the ranked labels in the existing user profile.

## Recommended Approach

Use a dedicated first-run onboarding screen gated by `HomeScreen`, backed by pure Dart label-scoring logic.

Why this approach:

- It creates a clear signup moment instead of a one-off dialog inside chat.
- It reuses the existing `UserProfileProvider` and Hive profile model.
- The scoring logic can be tested without widget complexity.

## Alternatives Considered

1. Settings-only questionnaire
Rejected because it does not satisfy signup-time labeling and would leave first-run routing unchanged.

2. Backend/dataset-only defaults
Rejected because the Flutter app already has local label persistence and the user explicitly called out a frontend implementation as the preferred path if feasible.

## Product Shape

- On first run, show onboarding instead of chat.
- Collect:
  - display name
  - a primary goal question
  - a preferred output style question
  - a current friction question
- Each answer contributes weighted points across the six existing labels.
- Save all six labels in ranked order to `preferredLabels`.
- Once saved, show the chat app normally and let the existing recommendation engine use those labels.

## Data Model

No schema expansion is required for the core feature.

- Existing `UserModel.preferredLabels` becomes the ranked label output from onboarding.
- `UserProfileProvider` should expose readiness/profile completion state so the app can gate first-run routing without flashing onboarding for returning users.

## Testing Plan

- Unit tests for the label-scoring function:
  - returns all six labels in ranked order
  - favors study help for study-oriented answers
  - favors wellbeing check-in for overwhelm-oriented answers
- Widget test for the first-run gate:
  - onboarding renders when no saved profile exists
  - chat renders once onboarding is completed

## Risks

- Async profile loading could briefly show the wrong screen; mitigate with an explicit provider-ready state.
- Persisting only top labels could lose coverage, so onboarding should save the full ranked list.
