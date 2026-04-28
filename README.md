# ORBIT - Multi-Role AI Assistant for Student Well-Being

ORBIT is a multi-agent AI assistant Flutter application designed to provide
intelligent, personalized support for college students. It is a label-driven,
skill-compositional agentic system that delivers context-aware support across
academic planning, stress monitoring, campus resources, career strategy, course
planning, and everyday life logistics.

## Overview

ORBIT addresses a core challenge facing students today: information
fragmentation across disconnected institutional systems. Academic deadlines live
in Canvas, schedules live in calendars, course difficulty information lives in
campus tools and review sites, career opportunities are dispersed across
platforms, and mental health resources remain siloed. Students are forced to
manually integrate these signals while already under pressure.

Rather than asking students to repeatedly explain their situation, ORBIT
constructs a dynamic ecosystem of specialized AI roles. Each role is composed of
modular agent skills that activate based on user-specific labels, chat history,
profile preferences, and behavioral state signals.

ORBIT combines:

- **Multi-Agent Architecture**: Specialized agents for student support domains.
- **Label-Driven Personalization**: Durable profile labels such as `vegan`,
  `commuter`, `movement_breaks`, `career_builder`, `canvas`, and
  `google_calendar`.
- **Local-First Processing**: Deterministic skill outputs with optional local
  Ollama/Gemma synthesis.
- **Real Data Integration**: Optional Canvas, Google Calendar, Google Maps,
  Google Places, and course/professor planning signals.
- **Student Monitor**: Stress, workload, notification, history, and action-plan
  surfaces.
- **Offline Demo Capability**: A deterministic UMD scenario when credentials or
  network access are unavailable.
- **Privacy-Aware Design**: Live data is opt-in and can be routed through a
  local Student Data Proxy.

### Key Components

- **ORBIT Agent Orchestrator**: Routes student requests to specialist roles and
  builds adaptive runtime skill priority.
- **Role Agents**: Academic planning, stress monitoring, campus resources,
  career strategy, life logistics, and course/professor planning.
- **Local LLM Client**: Optional Ollama-compatible client for local response
  synthesis.
- **Student Context Aggregator**: Builds unified snapshots from Canvas,
  Calendar, Places, Routes, proxy, and demo fixtures.
- **Support Intelligence Layer**: Converts labels, chat history, and imported
  signals into stress reports, follow-up questions, suggestions, and agent-ready
  skill blueprints.
- **Next Best Action Plan**: Converts student signals into concrete steps,
  tool/agent handoff, and a generated execution prompt.
- **Student Data Proxy**: Local Node backend scaffold for keeping Canvas/Google
  tokens outside the Flutter client.
- **Evaluation Fixture**: Reproducible 40-user UMD support-intelligence fixture
  used by tests and the Evaluation Readiness dashboard.

## Current Demo Features

- Local demo account with school email.
- 20-question onboarding intake.
- Initial support labels and durable profile labels.
- History-based preference extraction.
- Canvas/Calendar/Places/Routes demo snapshot.
- UMD Demo Path for a vegan student with deadlines, calendar pressure,
  food/location needs, route context, and stress alerts.
- Student Monitor with stress meter, workload chart, monitor history, focus
  break simulation, notification policy, and live/demo toggle.
- Configurable 45-minute default focus-break recommendation.
- Next Best Action Plan for converting signals into concrete steps.
- Course Planner with stress-aware semester balance, course workload, professor
  signal, PlanetTerp-style data, and chat export.
- Connected Apps screen for data sources, permissions, and tool status.
- Intelligence Dashboard with saved skills, feedback signal, agent audit trail,
  and Evaluation Readiness.
- Local deterministic fallback when Ollama or live credentials are missing.

## Quick Start

### Prerequisites

- Flutter SDK 3.4.1 or later.
- Dart, included with Flutter.
- Node.js, only needed for the optional Student Data Proxy.
- Ollama, optional for local LLM synthesis.
- Android Studio or a physical Android device for mobile testing.

### Windows Setup

Open PowerShell in the project root:

```powershell
cd C:\Users\zianz\OneDrive\Documents\GitHub\xfoundry
```

Install dependencies:

```powershell
& 'C:\Users\zianz\flutter\bin\flutter.bat' pub get
```

If `.env` does not exist:

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
```

Recommended no-token demo `.env`:

```env
LOCAL_LLM_ENDPOINT=http://127.0.0.1:11434
LOCAL_LLM_MODEL=gemma3:4b
EXTERNAL_DATA_ENABLED=false
STUDENT_DATA_PROXY_URL=
STUDENT_DATA_PROXY_USER_ID=demo
EXTERNAL_DATA_CACHE_SECONDS=300
EXTERNAL_DATA_TIMEOUT_SECONDS=8
CANVAS_BASE_URL=https://umd.instructure.com
CANVAS_ACCESS_TOKEN=
GOOGLE_ACCESS_TOKEN=
GOOGLE_MAPS_API_KEY=
CAMPUS_ROUTE_ORIGIN=McKeldin Library, College Park, MD
CAMPUS_ROUTE_DESTINATION=University Health Center, College Park, MD
```

## Run The App

### Desktop

Check available devices:

```powershell
& 'C:\Users\zianz\flutter\bin\flutter.bat' devices
```

Run Windows desktop:

```powershell
& 'C:\Users\zianz\flutter\bin\flutter.bat' run -d windows
```

If Windows desktop support is not enabled:

```powershell
& 'C:\Users\zianz\flutter\bin\flutter.bat' config --enable-windows-desktop
& 'C:\Users\zianz\flutter\bin\flutter.bat' run -d windows
```

Desktop is the best current demo path because it has the most room for the
monitor, planner, dashboards, and connected-apps surfaces.

### Web

Run in Chrome:

```powershell
& 'C:\Users\zianz\flutter\bin\flutter.bat' run -d chrome
```

Build web:

```powershell
& 'C:\Users\zianz\flutter\bin\flutter.bat' build web
```

### Mobile

Start an Android emulator or connect a physical Android phone with USB
debugging enabled.

Check devices:

```powershell
& 'C:\Users\zianz\flutter\bin\flutter.bat' devices
```

Run Android:

```powershell
& 'C:\Users\zianz\flutter\bin\flutter.bat' run -d android
```

Build APK:

```powershell
& 'C:\Users\zianz\flutter\bin\flutter.bat' build apk
```

APK output:

```text
build\app\outputs\flutter-apk\app-release.apk
```

On Windows, iOS cannot be built locally. Use Android, Windows desktop, or web.

## Demo Walkthrough

Use this path for testing the implemented product surfaces:

1. Start the desktop or web app.
2. Choose **Log in**.
3. Use the seeded demo account:
   - Email: `maya.chen@umd.edu`
   - Password: `12345`
   - Or click `Use Maya demo profile`.
4. Confirm the app opens directly to chat as Maya Chen, skipping signup, the
   guide, and the 20-question onboarding intake.
5. On the chat screen, confirm recommendation chips and support pulse appear.
6. Open **UMD Demo Path** from the chat header.
7. Review the student profile labels and signal summary.
8. Review **Next Best Action Plan**.
9. Review **Stress Monitor**, **Monitor History**, and **Notification Center**.
10. Click `Simulate 45m laptop block` and confirm the laptop-break nudge.
11. Change the focus-break threshold and confirm the recommendation updates.
12. Open **Report** from the chat header and switch between Now, 3 days, Week,
    Month, 6 months, Full year, YTD, and All time.
13. Review status metrics, trend bars, and recommendations for the selected
    range.
14. Review **Personalized Food Search** for vegan/location-aware routing.
15. Review **Next Semester Plan** for course/professor planning.
16. Review **UMD Resource Cards** and **Agent Execution Path**.
17. Click `Use this prompt in chat`.
18. Send the prompt and review the ORBIT trace beneath the assistant response.
19. Open **Course Planner** from the chat header and export a plan to chat.
20. Open **Connected Apps** and review data sources and permissions.
21. Open **Intelligence Dashboard** and review agent collaboration, skill
    registry, feedback, audit
    trail, and Evaluation Readiness.

The dashboard also includes **Demo Readiness** and **Investor Tour** panels.
Use `Reset Maya demo` before a pitch to re-seed Maya's profile, labels, prior
chats, monitor history, saved skill, feedback, and audit trace. The UMD Demo
Path includes the same reset action from its Data & Privacy panel.

## Optional Local LLM Synthesis

Install Ollama, then in a separate terminal:

```powershell
ollama pull gemma3:4b
ollama serve
```

Keep `.env` pointed at:

```env
LOCAL_LLM_ENDPOINT=http://127.0.0.1:11434
LOCAL_LLM_MODEL=gemma3:4b
```

ORBIT tries Gemini first when `API_KEY` is configured, falls back to local
Gemma/Ollama, then falls back to deterministic agent logic if both model paths
are unavailable.

## Optional Live Data Demo

The deterministic no-token demo is safest for repeatable presentations. For
live-data testing, start the local proxy in a second terminal:

```powershell
cd C:\Users\zianz\OneDrive\Documents\GitHub\xfoundry\backend\student-data-proxy
node server.mjs
```

Default proxy URL:

```text
http://127.0.0.1:8787
```

Configure Flutter `.env`:

```env
EXTERNAL_DATA_ENABLED=true
STUDENT_DATA_PROXY_URL=http://127.0.0.1:8787
STUDENT_DATA_PROXY_USER_ID=demo
```

Then in the app:

1. Open Settings.
2. Open Real Data Consent or Connected Apps.
3. Enable live Canvas/Google data.
4. Return to the chat screen.
5. Open UMD Demo Path and refresh live signals.

Useful proxy endpoints:

```text
GET  http://127.0.0.1:8787/health
GET  http://127.0.0.1:8787/auth/google/start?userId=demo
POST http://127.0.0.1:8787/connect/canvas
GET  http://127.0.0.1:8787/student/snapshot?userId=demo&taskText=food&preferenceTags=vegan
GET  http://127.0.0.1:8787/course-planning/umd?courses=CMSC216,STAT400&profileTags=stress_sensitive,commuter
```

Example Canvas connect:

```powershell
Invoke-RestMethod `
  -Uri http://127.0.0.1:8787/connect/canvas `
  -Method Post `
  -ContentType 'application/json' `
  -Body '{"userId":"demo","baseUrl":"https://umd.instructure.com","accessToken":"YOUR_CANVAS_TOKEN"}'
```

Do not commit real tokens.

## Configuration

### Core Variables

| Variable | Default | Description |
| --- | --- | --- |
| `LOCAL_LLM_ENDPOINT` | `http://127.0.0.1:11434` | Ollama-compatible endpoint. |
| `LOCAL_LLM_MODEL` | `gemma3:4b` | Local model name. |
| `EXTERNAL_DATA_ENABLED` | `false` | Enables live connector fetching. |
| `EXTERNAL_DATA_CACHE_SECONDS` | `300` | Snapshot cache duration. |
| `EXTERNAL_DATA_TIMEOUT_SECONDS` | `8` | Connector timeout. |
| `STUDENT_DATA_PROXY_URL` | empty | Optional local proxy URL. |
| `STUDENT_DATA_PROXY_USER_ID` | `demo` | Proxy user id. |

### Canvas Variables

| Variable | Description |
| --- | --- |
| `CANVAS_BASE_URL` | Canvas instance URL, usually `https://umd.instructure.com`. |
| `CANVAS_ACCESS_TOKEN` | Canvas API token for direct testing only. |

### Google Variables

| Variable | Description |
| --- | --- |
| `GOOGLE_ACCESS_TOKEN` | Google token for direct Calendar testing. |
| `GOOGLE_MAPS_API_KEY` | Google Maps/Places/Routes API key. |
| `CAMPUS_ROUTE_ORIGIN` | Route origin. |
| `CAMPUS_ROUTE_DESTINATION` | Route destination. |

## Testing

Prefer the bundled Dart and Flutter tool command on this Windows machine. It
avoids the plain `dart` PATH issue.

Analyze:

```powershell
& 'C:\Users\zianz\flutter\bin\cache\dart-sdk\bin\dart.exe' analyze lib test
```

Focused demo tests:

```powershell
& 'C:\Users\zianz\flutter\bin\cache\dart-sdk\bin\dart.exe' 'C:\Users\zianz\flutter\bin\cache\flutter_tools.snapshot' --no-version-check --suppress-analytics test --no-pub test\services\student_action_plan_service_test.dart test\services\evaluation_readiness_service_test.dart test\widget_test.dart
```

Full test suite:

```powershell
& 'C:\Users\zianz\flutter\bin\cache\dart-sdk\bin\dart.exe' 'C:\Users\zianz\flutter\bin\cache\flutter_tools.snapshot' --no-version-check --suppress-analytics test --no-pub
```

Latest local verification:

```text
dart analyze lib test: passed
focused demo tests: passed
full Flutter test suite: 95 tests passed
```

If Flutter cannot open
`C:\Users\zianz\flutter\bin\cache\lockfile`, run the same command from a normal
PowerShell terminal with access to the Flutter SDK cache. The current test suite
should complete in seconds once the SDK lockfile is accessible.

## Project Structure

```text
xfoundry/
├── backend/
│   └── student-data-proxy/  # Local proxy for Canvas/Google/course data
├── docs/                    # Architecture and roadmap docs
├── lib/
│   ├── agents/              # Multi-agent system
│   ├── apis/                # External API clients
│   ├── constants/           # App constants and environment config
│   ├── data_sources/        # Data access and UMD resource catalog
│   ├── demo/                # Deterministic demo scenario
│   ├── hive/                # Local persistence schemas
│   ├── models/              # Support, planning, and signal models
│   ├── providers/           # Provider state management
│   ├── screens/             # Chat, monitor, planner, dashboard, settings
│   ├── services/            # Business logic and recommendation services
│   ├── themes/              # App themes
│   ├── utilities/           # Helpers
│   ├── widgets/             # Reusable UI components
│   └── main.dart
├── test/                    # Unit, service, data-source, and widget tests
├── .env.example             # Local environment template
├── pubspec.yaml
└── README.md
```

## Architecture Deep Dive

### Problem Statement

University students operate inside fragmented digital ecosystems. The core
challenge is not the lack of tools, but the absence of cognitive coordination
across tools. Students must manually extract, prioritize, and act on information
scattered across:

- Canvas assignment deadlines.
- Google Calendar events.
- Course difficulty and professor signals.
- Internship and career timelines.
- Campus mental health and academic resources.
- Dining, transportation, and life logistics.

This burden is especially severe for students navigating unfamiliar academic
norms, first-generation students, students with ADHD or executive-function
challenges, financially constrained students, international students, and
students under sustained stress.

### Multi-Role Agentic Architecture

ORBIT avoids a monolithic chatbot design. It uses specialized role agents and
skill units that produce structured intermediate outputs before final response
synthesis.

Role areas include:

- Academic planning.
- Stress monitoring.
- Campus resource navigation.
- Course and professor planning.
- Career strategy.
- Life logistics.

### Agent Skills As Compositional Units

Agent skills are structured computational units containing:

- Constrained prompt templates.
- Optional retrieval components.
- Explicit tool or API access.
- Tool permission policy.
- Structured output expectations.

Skills are invoked by a deterministic workflow controller. This improves:

- Modularity.
- Interpretability.
- Efficiency on low-compute devices.
- Debuggability through independent tests.
- Safety, because irreversible actions can be blocked or approval-gated.

Example academic workflow:

```text
Deadline extraction
  -> calendar density analysis
  -> stress projection
  -> intervention selection
  -> resource or course-planning handoff
```

### Label-Driven Personalization

ORBIT uses labelization as structural configuration, not only tone
personalization. Labels influence which agents activate, which tools are
prioritized, and what constraints should be remembered.

Examples:

| Label | Effect |
| --- | --- |
| `vegan` / `plant_based` | Food/location search automatically avoids meat-centered suggestions. |
| `commuter` | Route, timing, and schedule planning become more important. |
| `movement_breaks` | Focus-session and break nudges become eligible. |
| `stress_sensitive` | Plans become smaller, safer, and less overload-prone. |
| `career_builder` | Course and schedule plans consider career/internship readiness. |
| `canvas` / `google_calendar` | Agent skills can prioritize imported academic and schedule signals. |

Labels are extracted from:

1. Initial onboarding intake.
2. Recent chat history.
3. Saved profile preferences.
4. Imported student signals.
5. Demo or live connector snapshots.

### Contextual Behavioral Integration

ORBIT integrates structured and behavioral data streams to reason about student
state:

- Canvas assignments and due dates.
- Google Calendar density.
- Campus route and place results.
- Course/professor workload signals.
- Optional focus-session and notification state.
- Student profile and preference labels.

The purpose is contextual reasoning, not surveillance. Data should remain
consent-based, explainable, and removable.

### Stress Modeling And Visualization

The monitor computes stress risk from workload clustering, calendar pressure,
deadline density, and profile context. The app visualizes:

- Stress risk.
- Weekly workload shape.
- Monitor history.
- Notifications and focus-break policy.
- Actionable student support steps.

Visualization is not just decoration. Monitor outputs feed future skill
selection and agent handoff.

### Chat Flow

1. User enters a message or selects a recommendation.
2. Profile labels, routing labels, and chat history are gathered.
3. Optional live/demo student signals are loaded.
4. The ORBIT orchestrator selects role agents and tool priorities.
5. Support intelligence creates questions, suggestions, and skill blueprints.
6. The action-plan layer converts signals into concrete next steps.
7. Ollama/Gemma can synthesize the final response when available.
8. Deterministic fallback is used when the local model is unavailable.
9. Feedback, audit traces, and chat history are stored locally.

## Security Notes

- Never commit `.env` files.
- Keep real Canvas and Google tokens outside the Flutter client.
- Prefer the Student Data Proxy for live-data testing.
- Keep demo fixture mode available for reliable presentations.
- Treat mental health output as support and routing, not diagnosis or therapy.
- Block or approval-gate irreversible actions.
- Production should add encrypted token storage, HTTPS, CSRF protection, rate
  limits, consent records, and revocation.

## Production Roadmap

The current app is a strong business-demo MVP, not a finished production
student-health platform. Important remaining work:

- Real backend auth with email verification.
- Account sync across devices.
- Production OAuth for Canvas and Google.
- Encrypted storage for tokens and sensitive local data.
- OS-level notifications on Android, iOS, desktop, and web.
- Real device activity/screen-time integration.
- Longitudinal evaluation and feedback dashboard.
- Official Testudo/umd.io section availability for course planning.
- Stronger crisis, self-harm, harassment, legal, and medical safety flows.
- Privacy and compliance review for student-data handling.

## Build Commands

Android APK:

```powershell
& 'C:\Users\zianz\flutter\bin\flutter.bat' build apk
```

Web:

```powershell
& 'C:\Users\zianz\flutter\bin\flutter.bat' build web
```

Windows:

```powershell
& 'C:\Users\zianz\flutter\bin\flutter.bat' build windows
```

## More Documentation

- [Local Multi-Agent System Architecture](docs/local-multi-agent-system.md)
- [Student Data Proxy Backend Setup](backend/student-data-proxy/README.md)
- [Recommendation Skill Router Plan](docs/recommendation-skill-router-plan.md)
