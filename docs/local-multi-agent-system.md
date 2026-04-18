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

## Signup And Initial Labels

The first-run signup flow now creates a local demo account with name and school
email, then asks 20 intake questions. The answers produce two kinds of labels:

- ranked support labels for the existing recommendation router:
  `planning`, `writing`, `study_help`, `summarization`, `image_analysis`, and
  `wellbeing_checkin`
- durable profile labels for personalization and tool routing, such as
  `vegan`, `plant_based`, `commuter`, `campus_navigation`,
  `movement_breaks`, `google_calendar`, `canvas`, `career_builder`, and
  `campus_resources`

The email is stored locally with the Hive profile for the current demo account.
This is not backend authentication yet; production auth should add a server or
identity provider while keeping the same label contract.

## UMD-First Data Connectors

`StudentContextAggregator` can fetch a real-data snapshot from:

- ORBIT Student Data Proxy
  - URL: `STUDENT_DATA_PROXY_URL`
  - recommended for desktop/web demos because OAuth tokens stay outside the
    Flutter client
  - current pull: unified Canvas, Google Calendar, Google Routes, and Google
    Places snapshot through `GET /student/snapshot`
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

For the production-shaped demo path, run the local proxy in
`backend/student-data-proxy` and set:

```env
EXTERNAL_DATA_ENABLED=true
STUDENT_DATA_PROXY_URL=http://127.0.0.1:8787
STUDENT_DATA_PROXY_USER_ID=demo
```

When the proxy is configured, the app asks it for the full student snapshot
before trying direct client-side connectors. If the proxy fails or is missing a
source, ORBIT records source notes and keeps the older direct/demo fallback path.

The app also has a student-facing consent gate in Settings > Real Data Consent.
Automatic Canvas, Calendar, Maps, and Places context requires both:

- build/runtime connector configuration through `.env` or `--dart-define`
- the in-app `Canvas/Google live data` switch turned on by the student

If either condition is missing, ORBIT stays local-first and adds a source note
explaining why live data was not fetched. Manual one-time imports remain
available for controlled demos, but automatic assistant context is gated.

Settings also includes a persistent `Use demo fixture` mode. When this is on,
ORBIT skips live connector calls even if credentials and consent exist, imports
the polished UMD vegan-student scenario as the current student snapshot, and
feeds that same fixture into chat, the monitor, label refresh, audit logs, and
agent synthesis. This gives judges a visible live/demo switch and keeps the
pitch deterministic without changing environment variables.

The Resource Navigator also has an offline UMD catalog so the demo stays
grounded without network credentials. It now covers the high-frequency UMD
student needs found in official campus pages and student forum patterns:
accommodations, Counseling Center crisis support, Help Center peer support,
TLTC/GSS/math/Keystone tutoring, OMSE, Career Center, Health Center, Dining
allergy/special-diet support, Campus Pantry, Resident Life, DOTS/Shuttle-UM,
NITE Ride, Paratransit, Terp Ride, UMD Guardian, Student Legal Aid, Student
Crisis Fund, Financial Aid, Dean of Students, Registrar, CARE to Stop Violence,
OCRSM/Title IX, ISSS, and the Writing Center. These entries are used as local
routing anchors and fallback recommendations; live details should come from a
future UMD resource retrieval backend.

Catalog entries now carry source-backed resource-card metadata: when to use the
resource, eligibility fit, suggested next action, and official URL. The demo
monitor surfaces these as UMD Resource Cards, and the campus-resource agent uses
the same metadata in its skill output so resource routing feels campus-specific
instead of generic.

## Demo Readiness

For a business demo, prepare two paths:

1. No-token path: run the app with no Canvas/Google credentials. ORBIT still
   shows support intelligence, uses onboarding/history labels, returns
   deterministic agent fallbacks if Ollama is offline, and grounds resource
   suggestions in the local UMD catalog.
2. Real-data path: run `backend/student-data-proxy` on the demo laptop, connect
   Canvas and Google under the demo user, point the app at
   `STUDENT_DATA_PROXY_URL`, and set
   `EXTERNAL_DATA_ENABLED=true`. In Settings > Real Data Consent, turn on
   `Canvas/Google live data` for the demo student. ORBIT imports those signals,
   refreshes routing labels, updates the support pulse, runs personalized live
   searches when the task needs them, and injects the structured snapshot into
   the local model prompt.

The chat header now includes a demo-status entry for a polished desktop/web
pitch path. It loads a UMD vegan-student scenario with Canvas deadlines,
calendar pressure, vegan Google Places results, a campus route, stress alerts,
tool-routing chips, and a one-click prompt that can be sent through the ORBIT
chat flow. The scenario is deterministic so judges see the same story every
time, while the evaluation story is grounded in
`test/fixtures/support_intelligence_eval_dataset.json`, a reproducible 40-user
fixture with 25 high-stress, 13 elevated, and 2 steady synthetic UMD profiles.

The same screen now also acts as a live monitor. On open, it requests the latest
`StudentSignalSnapshot` from the configured connectors and converts any live
Canvas, Calendar, Places, or Routes data into the stress meter, workload bars,
alerts, prompt, and agent-tool path. If no connected signals are available, it
falls back to the deterministic UMD demo fixture instead of showing a blank
dashboard.

The monitor also generates a Next Best Action Plan. This is the student-facing
decision layer that converts the closest Canvas deadline, current calendar
pressure, vegan/location matches, stress score, focus-break threshold, and
highest-matching UMD resource into concrete steps with the agent handoff and
skill prompt that would execute them. This makes the demo feel like a campus
support operating system instead of a generic chat answer.

The monitor also includes an in-app notification policy. It can raise stress,
deadline, and focus-duration nudges, including a demo control that simulates a
focused laptop block and recommends a walking/reset break when the student's
configured threshold is reached. The default is 45 minutes, and users can tune
the threshold from 15 to 180 minutes in Settings > Monitor or directly from the
demo monitor panel. This is intentionally implemented as a pure policy layer
first so it can later drive Android/iOS or desktop local notifications without
changing the alert logic.

Students can also control the notification policy before OS-level notification
plugins are added. Settings > Monitor now includes a student-nudge toggle, quiet
hours, quiet start/end sliders, and low/balanced/high sensitivity. Quiet hours
mute non-urgent nudges while still allowing urgent stress or deadline alerts,
and sensitivity changes how early deadline/stress nudges appear.

The monitor now persists local daily checkpoints in Hive. Each checkpoint saves
the student key, live/demo source, stress score, deadline count, calendar hours,
place/route counts, and active labels. The demo-status screen renders these
entries as a monitor-history trend so the pitch shows workload changing over
time instead of only a single snapshot. Same-day entries are upserted to avoid
spamming history during refreshes.

Assistant answers now include lightweight feedback chips: Helpful, Not helpful,
Wrong context, and Too much. Feedback is stored locally with the chat/message
id, response preview, timestamp, and agent trace. This gives the recommender a
measurable learning signal for future ranking, evaluation dashboards, and
per-user adaptation without requiring a backend for the demo.

Each assistant response also writes a local agent audit record. The record keeps
activated roles, generated skill ids, inferred tool priorities, data sources,
labels, model/fallback status, latency, and message previews. Assistant bubbles
surface the audit details when available so the demo can explain why ORBIT made
its routing decision instead of presenting the answer as an opaque chatbot
response.

The runtime skill now includes an explicit tool-permission policy. Low-risk
local reasoning tools are auto-allowed, connected-data tools such as Canvas
scan, Calendar review, live Places search, route planning, course/professor
planning, and schedule building are marked approval-required, and irreversible
actions such as submitting an
assignment or messaging an advisor are blocked in the demo. This is the
foundation for future approval gates before ORBIT becomes more autonomous.

## UMD Course And Professor Planning

ORBIT now includes a UMD next-semester planning layer because this is one of the
highest-value everyday student decisions. The course planner combines:

- profile labels such as `stress_sensitive`, `commuter`, `career_builder`, and
  `writing`
- current stress/workload state from the monitor
- UMD course candidates and requirement tags
- PlanetTerp course/professor review and historical grade signals
- cautious forum/reddit workload notes as anecdotal evidence

The demo monitor surfaces a Next Semester Plan panel that balances credits,
heavy technical classes, professor signal confidence, and workload risk. The
agent runtime also routes course/professor questions to
`course_professor_planner`, which is approval-required because it may query
connected or public external data.

The chat header also opens a dedicated Course Planner screen. It starts from a
deterministic UMD candidate fixture for reliable offline demos, then can fetch
live PlanetTerp course/professor signals when network access is available. The
screen compares target credits, stress pressure, course workload, professor
rating/review confidence, and GPA signals, then exports the plan back into chat
as structured agent context.

Settings now includes a Connected Apps screen. It shows the readiness and data
policy for the student-data proxy, Canvas, Google Calendar, Maps/Places,
PlanetTerp, Testudo/umd.io, device activity, and local notifications. Each card
lists what data the connector can use and the current tool permission level, so
approval-required tools are visible before ORBIT becomes more autonomous.

Source-backed live expansion is shaped around:

- PlanetTerp, which describes itself as a UMD community for informed course and
  professor decisions and exposes course, professor, and grade data.
- `umd.io`, the open UMD API for official course/professor data.
- Testudo/Schedule of Classes for final section availability and registration
  truth.

Forum/reddit opinions should help summarize workload patterns like projects,
exam count, attendance style, or perceived difficulty, but ORBIT should label
them as anecdotal and never treat them as the only source.

Generated support skills can now be saved into a local versioned registry.
Saving the current support-pulse skill stores the skill id, version, title,
summary, system prompt, starter prompt, tools, source labels, and stress band.
Repeated saves create `v1`, `v2`, and later versions, giving the demo a concrete
path from runtime skill generation to persistent skill assets.

The chat header includes an Intelligence Dashboard that brings these product
signals together: saved skill versions, feedback counts, recent feedback
examples, and recent agent audit logs. This gives the demo an explainability and
learning surface instead of leaving the new persistence layers hidden in local
storage.

The Intelligence Dashboard also includes an Evaluation Readiness panel. It
summarizes the 40-user fixture coverage, fulfillment thresholds, local feedback
and audit evidence, course-plan balance, and the remaining production gaps. This
is the judge-facing proof surface for why ORBIT is a measured student-support
system rather than a generic chatbot demo.

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
  demo credentials or the local student-data proxy.
- Web: viable if served with a small backend/proxy that owns OAuth token
  exchange, because browser apps should not store long-lived Canvas or Google
  secrets directly.

The agent contract stays the same across all three surfaces: integrations feed
`StudentSignalSnapshot`, the snapshot becomes structured context, and ORBIT
uses that context for role selection and synthesis.
