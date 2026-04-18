# Local Multi-Agent System

This implementation adds the ORBIT multi-agent layer behind the existing chat
framework. The UI, recommendation chips, Hive chat history, and routing metadata
stay in place; text chat now goes through a local-first agent workflow instead
of a cloud model.

## Architecture

The project proposal frames ORBIT as a label-driven, skill-compositional
multi-role agentic system. The app implementation follows that shape:

1. `ChatProvider` captures the user message, selected recommendation metadata,
   recent labels, assumed onboarding labels, conversation history, and any
   configured real-data snapshot.
2. `OrbitAgentOrchestrator` acts as the deterministic workflow controller.
3. Role agents produce structured skill outputs:
   - `AcademicPlanningAgent`
   - `StressMonitoringAgent`
   - `CampusResourceAgent`
   - `CareerStrategyAgent`
   - `LifeLogisticsAgent`
4. An adaptive runtime skill is generated from the current task, signup/history
   labels, imported activity signals, selected template metadata, and tool
   hints. This updates role priority and tool order before the response is
   synthesized.
5. `OllamaLocalLlmClient` sends one synthesis request to a local model.
6. If the local model is unavailable, ORBIT returns a deterministic fallback
   built from the activated agent skill outputs.

This keeps low-compute devices in mind: role selection and skill outputs are
deterministic, while the local model is used for final synthesis only.

## Local Model Setup

Default configuration:

```env
LOCAL_LLM_ENDPOINT=http://127.0.0.1:11434
LOCAL_LLM_MODEL=gemma2:2b
```

With Ollama installed:

```powershell
ollama pull gemma2:2b
ollama serve
```

Run Flutter normally after the model server is available. The app can also run
without Ollama; responses will use deterministic ORBIT fallback logic.

## Recommendation Team Boundary

The multi-agent layer can run before the full recommendation system is ready.
It currently uses:

- selected prompt label from the current composer
- recent chat labels from Hive history
- preferred labels stored on the user profile
- inferred labels from optional real-data connectors
- locally extracted stable preferences from recent chat history, such as
  `vegan`, `plant_based`, `gluten_free`, `commuter`, and
  `international_student`
- assumed onboarding labels:
  `college_student`, `academic_planning`, `stress_sensitive`,
  `career_builder`, `life_logistics`, `local_first`

## UMD-First Data Connectors

`StudentContextAggregator` can fetch a real-data snapshot from:

- UMD ELMS-Canvas via Canvas REST API
  - default base URL: `https://umd.instructure.com`
  - token: `CANVAS_ACCESS_TOKEN`
  - current pull: active courses and upcoming assignments
- Google Calendar API
  - token: `GOOGLE_ACCESS_TOKEN`
  - current pull: next 7 days of primary calendar events
- Google Routes API
  - key: `GOOGLE_MAPS_API_KEY`
  - current pull: default walking route between two UMD campus locations
- Google Places Text Search API
  - key: `GOOGLE_MAPS_API_KEY`
  - current pull: task-triggered place results near University of Maryland
    College Park
  - personalization: dietary or logistics labels rewrite the query before the
    API call. For example, if recent history or profile labels contain `vegan`
    and the student asks for food, ORBIT searches `vegan food near University of
    Maryland College Park` without requiring an extra prompt.

The snapshot computes:

- deadlines in the next 7 days
- calendar hours in the next 7 days
- stress risk score from deadline density and calendar occupancy
- inferred labels such as `academic_planning`, `calendar_density`,
  `campus_navigation`, `life_logistics`, and `wellbeing_checkin`

If credentials are absent or a fetch fails, the app keeps working and records a
source note for the agent prompt instead of crashing.

External data is intentionally opt-in for production safety:

```env
EXTERNAL_DATA_ENABLED=false
EXTERNAL_DATA_CACHE_SECONDS=300
EXTERNAL_DATA_TIMEOUT_SECONDS=8
```

Set `EXTERNAL_DATA_ENABLED=true` only for a trusted desktop/web demo or a future
backend-backed OAuth flow. Snapshot fetches are cached for the configured TTL and
deduplicated while a request is in flight, so chat messages do not repeatedly
hammer Canvas or Google APIs.

The Resource Navigator also has an offline UMD catalog so the demo stays
grounded without network credentials. It includes Accessibility and Disability
Service, Counseling Center, Teaching and Learning Transformation Center,
University Career Center, University Health Center, UMD Dining Services, Campus
Pantry, Resident Life, Department of Transportation Services, International
Student and Scholar Services, and the Writing Center. These entries are used as
local routing anchors and fallback recommendations; live details should come
from a future UMD resource retrieval backend.

## Demo Readiness

For a business demo, prepare two paths:

1. No-token path: run the app with no Canvas/Google credentials. ORBIT still
   shows support intelligence, uses onboarding/history labels, returns
   deterministic agent fallbacks if Ollama is offline, and grounds resource
   suggestions in the local UMD catalog.
2. Real-data path: run a desktop build with `.env` credentials for Canvas,
   Google Calendar, and Google Maps/Places, and set
   `EXTERNAL_DATA_ENABLED=true`. ORBIT imports those signals, refreshes routing
   labels, updates the support pulse, runs personalized live searches when the
   task needs them, and injects the structured snapshot into the local model
   prompt.

Recommended local model choices:

- `gemma2:2b` for lower-memory laptops and quick demos.
- `qwen2.5:3b-instruct` if available locally and the machine can handle a
  little more latency.

The default remains `gemma2:2b` because the phone/laptop compute budget is low.

## Mobile, Desktop, And Web Split

For the demo, use the phone as the lightweight assistant surface and use a
desktop/web build for heavier integration work.

- Mobile: local assistant, labels, chat history, deterministic fallback, optional
  connection to a local model server on the same network.
- Desktop: best place to run Ollama plus Canvas/Google fetches with user-owned
  demo credentials.
- Web: viable if served with a small backend/proxy that owns OAuth token
  exchange, because browser apps should not store long-lived Canvas or Google
  secrets directly.

The agent contract stays the same across all three surfaces: integrations feed
`StudentSignalSnapshot`, the snapshot becomes structured context, and ORBIT
uses that context for role selection and synthesis.
