# ORBIT - UMD Student Support Agent

ORBIT is a Flutter app for a UMD-first student support assistant. It is not just
a chatbot: it combines onboarding labels, chat history, Canvas-style deadlines,
calendar pressure, campus resources, course/professor planning, food/location
preferences, stress monitoring, and local multi-agent orchestration into a
student action plan.

The current build is a strong business-demo MVP. It runs without cloud LLMs by
using deterministic agent skills and optional local Ollama/Gemma synthesis. It
also has an optional local Student Data Proxy for Canvas, Google Calendar,
Google Places, Google Routes, and PlanetTerp-style course planning.

## What The Demo Can Show Now

- Local email-based demo signup and 20-question onboarding intake.
- Durable student labels such as `vegan`, `plant_based`, `commuter`,
  `movement_breaks`, `canvas`, `google_calendar`, and `career_builder`.
- Multi-agent routing across academic planning, stress monitoring, campus
  resources, career planning, life logistics, and course/professor planning.
- UMD Demo Path for a vegan UMD student with Canvas deadlines, calendar
  pressure, food/location needs, walking route context, and stress alerts.
- Student Monitor with stress score, workload chart, monitor history, focus
  break simulation, notification policy, and privacy/live-data toggle.
- Next Best Action Plan that converts signals into concrete student-safe steps,
  agent handoff, and a generated skill prompt.
- Course Planner for next-semester course/professor recommendations using
  workload, stress, credits, profile labels, and PlanetTerp-style signals.
- Connected Apps screen showing proxy, Canvas, Calendar, Maps/Places,
  PlanetTerp/Testudo/umd.io, device activity, notifications, and permissions.
- Intelligence Dashboard with saved skills, feedback signal, audit trail, and
  Evaluation Readiness against the 40-user fixture.
- Deterministic demo fallback when live credentials or local LLM are missing.
- Optional Ollama/Gemma local LLM synthesis.

## Exact Setup On This Windows Machine

Open PowerShell in the project root:

```powershell
cd C:\Users\zianz\OneDrive\Documents\GitHub\xfoundry
```

Install dependencies:

```powershell
& 'C:\Users\zianz\flutter\bin\flutter.bat' pub get
```

If `.env` does not exist, create it from the example:

```powershell
if (-not (Test-Path .env)) { Copy-Item .env.example .env }
```

For a safe no-token judge demo, keep these values:

```env
LOCAL_LLM_ENDPOINT=http://127.0.0.1:11434
LOCAL_LLM_MODEL=gemma2:2b
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

## Run The Desktop App

Check devices:

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

Desktop is the recommended judge path because it has the most room for the
monitor, course planner, connected apps, and dashboard screens.

## Run The Web App

Run Chrome/web:

```powershell
& 'C:\Users\zianz\flutter\bin\flutter.bat' run -d chrome
```

Build web for a static demo:

```powershell
& 'C:\Users\zianz\flutter\bin\flutter.bat' build web
```

Web is the best backup if Windows desktop has platform setup issues.

## Run The Mobile App

Start an Android emulator from Android Studio, or connect a physical Android
phone with USB debugging enabled. Then check devices:

```powershell
& 'C:\Users\zianz\flutter\bin\flutter.bat' devices
```

Run on Android:

```powershell
& 'C:\Users\zianz\flutter\bin\flutter.bat' run -d android
```

Build an Android APK:

```powershell
& 'C:\Users\zianz\flutter\bin\flutter.bat' build apk
```

APK output:

```text
build\app\outputs\flutter-apk\app-release.apk
```

On Windows, iOS cannot be built locally. Use Android, Windows desktop, or web
for judging.

## Optional Local LLM: Ollama/Gemma

Install Ollama, then in a separate terminal:

```powershell
ollama pull gemma2:2b
ollama serve
```

Keep `.env` pointed at:

```env
LOCAL_LLM_ENDPOINT=http://127.0.0.1:11434
LOCAL_LLM_MODEL=gemma2:2b
```

If Ollama is not running, the app still works through deterministic agent
fallbacks. That is intentional for low-compute laptops and mobile devices.

## Optional Live Data Demo

The no-token demo is the safest judge path. For live-data rehearsal, run the
Student Data Proxy in a second PowerShell window:

```powershell
cd C:\Users\zianz\OneDrive\Documents\GitHub\xfoundry\backend\student-data-proxy
node server.mjs
```

Default proxy URL:

```text
http://127.0.0.1:8787
```

In the Flutter app `.env`, enable the proxy:

```env
EXTERNAL_DATA_ENABLED=true
STUDENT_DATA_PROXY_URL=http://127.0.0.1:8787
STUDENT_DATA_PROXY_USER_ID=demo
```

Then in the app:

1. Open Settings.
2. Open Real Data Consent / Connected Apps.
3. Turn on live Canvas/Google data.
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

Do not put real tokens in Git.

## Judge Demo Script

Use this path for a polished 5-8 minute pitch.

1. Start Windows desktop or Chrome:

   ```powershell
   & 'C:\Users\zianz\flutter\bin\flutter.bat' run -d windows
   ```

2. Complete signup:
   - Use a school email such as `maya.chen@umd.edu`.
   - Answer the 20 intake questions with a vegan, busy, stress-sensitive,
     career-building UMD student profile.

3. On the chat screen, explain the core idea:
   - ORBIT remembers labels and uses them to route agents and tools.
   - A vegan student does not need to re-prompt "vegan" every time.
   - A stressed student gets smaller, safer plans.

4. Open the UMD Demo Path from the chat header.
   Show:
   - Student profile labels.
   - Stress Monitor.
   - Next Best Action Plan.
   - Monitor History.
   - Notification Center and the 45-minute focus-break simulation.
   - Personalized Food Search.
   - Next Semester Plan.
   - UMD Resource Cards.
   - Agent Execution Path.
   - Data & Privacy live/demo toggle.

5. Click `Simulate 45m laptop block`.
   Show that ORBIT recommends a break at the configured threshold.

6. Use the focus-break control to change the threshold.
   Show that this is customizable and not hard-coded.

7. Click `Use this prompt in chat`.
   The chat composer should load the vegan UMD scenario prompt.

8. Open Course Planner from the chat header.
   Show:
   - Stress-aware semester balance.
   - Credits and heavy-course risk.
   - Professor/review-style signals.
   - `Use in chat` export.

9. Open Connected Apps from Settings or the header path.
   Show:
   - Which data sources are connected, demo-only, approval-required, or blocked.
   - Canvas, Google Calendar, Maps/Places, PlanetTerp/Testudo/umd.io, device
     activity, and notification permissions.

10. Open Intelligence Dashboard.
    Show:
    - Skill Registry.
    - Feedback Signal.
    - Agent Audit Trail.
    - Evaluation Readiness with 40-user fixture coverage and production gaps.

11. Close with the product differentiation:
    - Generic chatbots answer a prompt.
    - ORBIT monitors the student's academic, schedule, campus, preference, and
      stress signals, then creates a safe next action and agent workflow.

## Test Commands

Prefer the bundled Dart + Flutter tool command below on this machine. It avoids
the plain `dart` PATH issue and keeps tests bounded.

Analyze:

```powershell
& 'C:\Users\zianz\flutter\bin\cache\dart-sdk\bin\dart.exe' analyze lib test
```

Focused tests for the latest demo work:

```powershell
& 'C:\Users\zianz\flutter\bin\cache\dart-sdk\bin\dart.exe' 'C:\Users\zianz\flutter\bin\cache\flutter_tools.snapshot' --no-version-check --suppress-analytics test --no-pub test\services\student_action_plan_service_test.dart test\services\evaluation_readiness_service_test.dart test\widget_test.dart
```

Full test suite:

```powershell
& 'C:\Users\zianz\flutter\bin\cache\dart-sdk\bin\dart.exe' 'C:\Users\zianz\flutter\bin\cache\flutter_tools.snapshot' --no-version-check --suppress-analytics test --no-pub
```

Latest verification:

```text
dart analyze lib test: passed
focused demo tests: passed
full Flutter test suite: 95 tests passed
```

If Flutter says it cannot open
`C:\Users\zianz\flutter\bin\cache\lockfile`, run the same command from a normal
PowerShell terminal with user permissions. The app tests themselves are not
supposed to take hours; the current full suite completes in seconds on this
machine once the Flutter SDK cache lock is accessible.

## Updates From This Afternoon

Commit summary:

```text
Build production-shaped ORBIT student demo path
```

Commit description:

```text
- add Connected Apps screen for proxy, Canvas, Calendar, Maps/Places,
  PlanetTerp/Testudo/umd.io, device activity, notifications, data-use summaries,
  and tool permission status
- add UMD course/professor planning flow with stress-aware credit balance,
  professor/workload signals, PlanetTerp hydration, and chat export
- improve notification policy with configurable 45-minute default focus break,
  quiet hours, sensitivity, and disabled-notification states
- add Evaluation Readiness service and dashboard panel for 40-user fixture
  coverage, fulfillment checks, feedback/audit evidence, course-plan balance,
  and production gaps
- add Next Best Action Plan service that converts Canvas deadlines, calendar
  pressure, vegan/location context, stress score, UMD resources, and focus-break
  settings into concrete steps, agent handoff, and a generated skill prompt
- surface the action plan in the UMD Demo Path / Student Monitor screen
- expand widget and service tests for connected apps, course planning,
  notification controls, readiness dashboard, and action-plan demo path
- document the judge demo flow, desktop/mobile/web run commands, live-data
  proxy path, and remaining business-level gaps
```

## Current Architecture

```text
Onboarding labels
  -> profile and routing labels
  -> recommendation and support-intelligence bundle
  -> adaptive skill blueprint
  -> multi-agent orchestrator
  -> optional local LLM synthesis

Canvas / Calendar / Places / Routes / course data
  -> StudentSignalSnapshot
  -> stress and workload monitor
  -> next-best-action plan
  -> agent tool priority
  -> UMD resources and course planner
```

Core modules:

```text
lib/agents/                         multi-agent orchestration
lib/data_sources/                   Canvas/Google/proxy/UMD resource data
lib/demo/                           deterministic UMD judge scenario
lib/hive/                           local persistence models
lib/models/                         support, planning, and data models
lib/providers/                      app state and profile flow
lib/screens/                        chat, monitor, planner, dashboard, settings
lib/services/                       business logic and recommendation services
backend/student-data-proxy/         local OAuth/token proxy scaffold
test/                               unit, service, data-source, and widget tests
```

## What Is Still Missing For Production

The current version is strong enough for a business demo, but not yet a fully
production student-health company. The biggest remaining work:

- Real backend auth with email verification, session management, and account
  sync across devices.
- Production OAuth for Canvas and Google under the signed-in student.
- Encrypted token storage, token revocation, consent records, and audit logs.
- Real OS notifications on Android/iOS/desktop with permission prompts, quiet
  hours, and background scheduling.
- Real device activity/screen-time integrations instead of the current
  simulation/policy layer.
- Deeper evaluation dashboard with longitudinal user feedback, not only local
  fixture checks.
- More realistic datasets and partner-consented UMD data exports.
- Official Testudo/umd.io section availability and registration constraints in
  the course planner.
- Human-in-the-loop safety escalation for crisis, self-harm, harassment, legal,
  and medical situations.
- Security review for the Student Data Proxy: HTTPS, CSRF protection, rate
  limiting, encrypted storage, and deployment hardening.
- Privacy/legal work: FERPA, HIPAA-adjacent wellbeing boundaries, data retention
  policy, and university partner approvals.

## Business-Level Differentiation

To compete against generic chatbots, ORBIT should stay vertical:

- UMD-first resource graph instead of generic advice.
- Canvas + Calendar + campus routes + dining/location + course/professor
  planning in one workflow.
- Preference memory, such as vegan food routing without repeated prompting.
- Stress and workload monitoring, not just chat.
- Proactive next-best-action planning when deadlines, focus, or stress cross
  thresholds.
- Local-first AI path for privacy, cost, and offline demos.
- Skill-generating multi-agent system with visible tool permissions and traces.
- Student wellbeing and academic success evaluation, not only conversation
  quality.

No product can guarantee winning a $2M competition, but the best path is to make
the demo prove one thing clearly: ORBIT reduces student cognitive load by
turning scattered campus signals into safe, personal next actions.

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

## Security Notes

- Do not commit `.env` files.
- Keep real Canvas and Google tokens outside the Flutter client.
- Prefer the Student Data Proxy for live demos.
- Keep demo fixture mode available for judging reliability.
- Treat mental health output as support and routing, not diagnosis or therapy.
- Block irreversible actions unless the student explicitly approves them.

## More Documentation

- [Local Multi-Agent System Architecture](docs/local-multi-agent-system.md)
- [Student Data Proxy Backend Setup](backend/student-data-proxy/README.md)
- [Recommendation Skill Router Plan](docs/recommendation-skill-router-plan.md)
