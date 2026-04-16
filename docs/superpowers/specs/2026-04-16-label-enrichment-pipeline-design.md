# Label Enrichment Pipeline Design

## Goal

Extend Orbit's label personalization beyond signup by combining ongoing chat behavior with optional imported activity data from external systems such as Google Calendar and Canvas.

## Approach

Keep the original signup ranking as the stable base signal, then layer on:

- local chat-history evidence
- explicit in-app label selections during later chats
- optional one-off imports from Google Calendar
- optional one-off imports from Canvas

The app should merge those signals into a single ranked routing list without replacing stronger direct intent signals like an actively selected label or attached image.

## Data Model

- `preferredLabels` stays the canonical signup + direct-preference ranking
- `importedLabels` stores the merged ranking derived from external imports
- `importedSources` stores the external systems that contributed imported labels
- the final routing order is computed at runtime from preferred labels, imported labels, and chat history

## Pipeline

1. Load saved profile labels.
2. Read local chat history and derive additional score evidence from:
   - selected labels
   - saved prompt/response text
   - image usage
   - saved template ids
3. Optionally fetch Google Calendar or Canvas activity and infer label rankings from returned items.
4. Merge all evidence into one ranked label list.
5. Feed that enriched label list into the prompt router.

## UI Surface

Settings owns the import/config workflow:

- show current routing-focus chips
- refresh from local history
- import Google Calendar labels
- import Canvas labels
- clear imported signals

## Risks

- token-based imports are intentionally lightweight and do not implement OAuth flows
- imported rankings are heuristic summaries, not raw-data mirrors
- the app still needs manual device validation for import/error states
