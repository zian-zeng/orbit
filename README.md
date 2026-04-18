# ORBIT - Multi-Role AI Assistant for Student Well-Being

A sophisticated multi-agent AI chatbot Flutter application designed to provide intelligent, personalized support for college students. ORBIT is a label-driven, skill-compositional multi-role agentic system that delivers context-aware advice across academic planning, stress monitoring, campus resources, career strategy, and life logistics.

## 📋 Overview

ORBIT addresses a core challenge facing students today: information fragmentation across disconnected institutional systems. Academic deadlines live in Canvas, scheduling is scattered across calendars, career opportunities are dispersed across platforms, and mental health resources remain siloed. Rather than requiring students to manually integrate these signals, ORBIT constructs a dynamic ecosystem of specialized AI roles—each composed of modular agent skills—that activate based on user-specific labels and behavioral state signals.

ORBIT is an advanced AI assistant that combines:
- **Multi-Agent Architecture**: Specialized agents for different support domains
- **Local-First Processing**: Deterministic skill outputs with optional local LLM synthesis
- **Real Data Integration**: Connections to Canvas, Google Calendar, Google Maps, and Google Places
- **Offline Capabilities**: Full functionality without internet connectivity
- **Student Privacy**: Tokens stay outside the Flutter client via the Student Data Proxy backend

### Key Components

- **ORBIT Agent Orchestrator**: Routes student queries to appropriate specialist agents
- **Role Agents**: Dedicated agents for specific support domains
- **Local LLM Client**: Integrates with Ollama for response synthesis (optional)
- **Student Context Aggregator**: Fetches unified snapshots from Canvas, Google Calendar, Maps, and Places
- **Recommendation System**: Delivers personalized support suggestions
- **Voice Input**: Speech-to-text capabilities for hands-free interaction

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** (3.4.1 or later)
- **Dart** (included with Flutter)
- **Node.js** (for optional student data proxy backend)
- **Ollama** (optional, for local LLM synthesis)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd xfoundry
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**
   
   Create a `.env` file in the project root:
   ```env
   # Google Generative AI (Fallback LLM)
   GOOGLE_API_KEY=your_google_api_key_here
   
   # Local LLM Configuration (Optional)
   LOCAL_LLM_ENDPOINT=http://127.0.0.1:11434
   LOCAL_LLM_MODEL=gemma2:2b
   
   # External Data Integration (Optional)
   EXTERNAL_DATA_ENABLED=false
   EXTERNAL_DATA_CACHE_SECONDS=300
   EXTERNAL_DATA_TIMEOUT_SECONDS=8
   
   # For Canvas/Google live data (when using Student Data Proxy)
   STUDENT_DATA_PROXY_URL=http://127.0.0.1:8787
   STUDENT_DATA_PROXY_USER_ID=demo
   ```

4. **Run the app**
   ```bash
   # For Android
   flutter run -d android
   
   # For iOS
   flutter run -d ios
   
   # For Web
   flutter run -d web
   
   # For Windows
   flutter run -d windows
   ```

## 🔧 Configuration

### Environment Variables

#### Core Configuration
| Variable | Default | Description |
|----------|---------|-------------|
| `LOCAL_LLM_ENDPOINT` | `http://127.0.0.1:11434` | Ollama server endpoint |
| `LOCAL_LLM_MODEL` | `gemma2:2b` | Local model to use |
| `GOOGLE_API_KEY` | Required | Google Generative AI API key (fallback) |

#### External Data Integration
| Variable | Default | Description |
|----------|---------|-------------|
| `EXTERNAL_DATA_ENABLED` | `false` | Enable Canvas/Google data connectors |
| `EXTERNAL_DATA_CACHE_SECONDS` | `300` | Cache duration for data snapshots |
| `EXTERNAL_DATA_TIMEOUT_SECONDS` | `8` | Timeout for data fetching |
| `STUDENT_DATA_PROXY_URL` | - | Proxy server URL for secure data access |
| `STUDENT_DATA_PROXY_USER_ID` | - | User ID for proxy authentication |

#### Canvas Integration
| Variable | Description |
|----------|-------------|
| `CANVAS_BASE_URL` | Canvas instance URL (e.g., `https://umd.instructure.com`) |
| `CANVAS_ACCESS_TOKEN` | Canvas API access token |

#### Google Integration
| Variable | Description |
|----------|-------------|
| `GOOGLE_ACCESS_TOKEN` | Google API access token (for Calendar, Maps, Places) |
| `GOOGLE_MAPS_API_KEY` | Google Maps API key |
| `CAMPUS_ROUTE_ORIGIN` | Starting location for route queries |
| `CAMPUS_ROUTE_DESTINATION` | Destination for route queries |

## 🎯 Features

### Multi-Agent System

The ORBIT orchestrator routes queries to specialized agents:

- **Academic Planning Agent**: Course selection, study strategies, degree planning
- **Stress Monitoring Agent**: Workload analysis, wellness recommendations
- **Campus Resource Agent**: Localized resource suggestions with UMD catalog
- **Career Strategy Agent**: Career planning, internship guidance
- **Life Logistics Agent**: Schedule optimization, commute planning, dining

### Real Data Integration

With proper configuration, the app can access:

- **Canvas**: Active courses, upcoming assignments, grade distribution
- **Google Calendar**: Schedule analysis, calendar density metrics
- **Google Routes**: Campus navigation with realistic travel times
- **Google Places**: Food, study spaces, and other resources near campus

Data is fetched through the optional Student Data Proxy backend for security, or directly via API tokens.

### User Profiles & Personalization

- **Intake Questions**: 20-question onboarding to establish support labels
- **Preference Learning**: Extracts dietary, mobility, and logistics preferences from chat history
- **Profile Labels**: Persistent labels like `vegan`, `commuter`, `career_builder` for personalization
- **Real-Time Updates**: Refreshes support routing based on calendar density, deadline proximity, and other signals

### Offline Capabilities

- Full functionality without internet (no external data)
- Deterministic agent skill outputs
- Local chat history storage with Hive
- Fallback responses when local model unavailable
- Local UMD resource catalog

### Voice & Accessibility

- Speech-to-text input support
- Markdown rendering for rich text responses
- Image picker integration for visual inputs
- Material Design with light/dark themes

## 🛠️ Setup Instructions by Use Case

### No-Token Demo (Local-Only)

Quickest setup for demonstrations without credential configuration:

```bash
# Install dependencies
flutter pub get

# Create .env with minimal config
echo "GOOGLE_API_KEY=demo_key" > .env

# Run the app
flutter run -d web  # Recommended for demos
```

The app will:
- Create a local demo account via signup flow
- Use deterministic agent responses
- Show local UMD resource suggestions
- Provide fallback responses if Ollama is unavailable

### Real-Data Demo Path (Recommended)

For comprehensive demonstrations with live student data:

1. **Start the Student Data Proxy backend**
   ```powershell
   cd backend/student-data-proxy
   
   # Configure .env with Canvas and Google credentials
   # (See backend README for full configuration)
   
   node server.mjs
   # Server will run on http://127.0.0.1:8787
   ```

2. **Configure Flutter app .env**
   ```env
   EXTERNAL_DATA_ENABLED=true
   STUDENT_DATA_PROXY_URL=http://127.0.0.1:8787
   STUDENT_DATA_PROXY_USER_ID=demo
   ```

3. **Run the app**
   ```bash
   flutter run -d web
   ```

4. **Enable live data in Settings**
   - Open Settings > Real Data Consent
   - Toggle `Canvas/Google live data` ON
   - ORBIT will now fetch and integrate real student data

### Local LLM Synthesis (Ollama)

For advanced response synthesis using a local model:

1. **Install Ollama**
   ```bash
   # Download from https://ollama.ai
   ```

2. **Pull the model**
   ```powershell
   ollama pull gemma2:2b
   ```

3. **Start Ollama server**
   ```powershell
   ollama serve
   # Runs on http://127.0.0.1:11434
   ```

4. **Configure Flutter .env**
   ```env
   LOCAL_LLM_ENDPOINT=http://127.0.0.1:11434
   LOCAL_LLM_MODEL=gemma2:2b
   ```

5. **Run the app normally**
   ```bash
   flutter run
   ```

When both Ollama and the app are running, ORBIT will use the local model for final response synthesis while maintaining deterministic agent skill selection.

## 📁 Project Structure

```
xfoundry/
├── lib/
│   ├── agents/              # Multi-agent system implementations
│   ├── apis/                # External API clients (Canvas, Google, etc.)
│   ├── constants/           # App constants and configuration
│   ├── data_sources/        # Data access layer
│   ├── demo/                # Demo/fixture data
│   ├── hive/                # Local database schemas
│   ├── models/              # Data models and entities
│   ├── providers/           # State management (Provider pattern)
│   ├── screens/             # UI screens
│   ├── services/            # Business logic services
│   ├── themes/              # Material Design themes
│   ├── utilities/           # Helper functions and utilities
│   ├── widgets/             # Reusable UI components
│   └── main.dart            # App entry point
├── backend/
│   └── student-data-proxy/  # Node.js backend for secure data access
├── test/                    # Unit and widget tests
├── pubspec.yaml             # Flutter dependencies and configuration
├── analysis_options.yaml    # Dart linting rules
└── .env                     # Environment variables (create locally)
```

## 📦 Dependencies

### Core Flutter Packages
- **provider**: State management and dependency injection
- **hive** & **hive_flutter**: Local, encrypted database
- **flutter_dotenv**: Environment variable loading

### AI & Language
- **google_generative_ai**: Google's Generative AI API (fallback LLM)
- **flutter_markdown**: Rich text rendering

### Device Features
- **speech_to_text**: Voice input capture
- **image_picker**: Photo/document selection
- **path_provider**: Platform-specific directory access

### Utilities
- **uuid**: Unique identifier generation
- **cupertino_icons**: iOS-style icons

### Development
- **build_runner**: Code generation
- **hive_generator**: Hive model generation
- **flutter_test**: Testing framework
- **flutter_lints**: Dart linting rules

## 🧪 Testing

Run tests with:
```bash
# All tests
flutter test

# Single test file
flutter test test/widget_test.dart

# With coverage
flutter test --coverage
```

Test structure mirrors the lib/ structure:
- `test/agents/` - Agent logic tests
- `test/data_sources/` - Data layer tests
- `test/providers/` - State management tests
- `test/services/` - Business logic tests
- `test/demo/` - Demo data and fixtures

## 🏗️ Building for Production

### Android
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk

# Or for App Bundle (Google Play)
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### iOS
```bash
flutter build ios --release
# Open with: open ios/Runner.xcworkspace
```

### Web
```bash
flutter build web --release
# Output: build/web/
```

### Windows
```bash
flutter build windows --release
# Output: build/windows/runner/Release/
```

### Build with Environment Variables
```bash
flutter build apk --release \
  --dart-define=GOOGLE_API_KEY=your_key \
  --dart-define=LOCAL_LLM_ENDPOINT=http://localhost:11434
```

## 🔐 Security Notes

### Data Protection
- Canvas and Google tokens are **never stored in the Flutter app**
- Use the Student Data Proxy backend for OAuth token management
- Local chat history and profiles are encrypted with Hive
- API calls are cached for 5 minutes to reduce token usage

### Privacy Consent
- Students must opt-in to live data connectors
- Data fetches fail gracefully; app continues with local fallbacks
- Settings include persistent `Use demo fixture` toggle for privacy-first demos

### Best Practices
- **Never commit `.env` files** - add to `.gitignore`
- **Use app-specific API keys** - rotate keys regularly
- **Enable CORS** on backend services for web deployments
- **Use HTTPS** for production deployments

## 📚 Architecture Deep Dive

### Problem Statement

University students today operate within highly fragmented digital ecosystems. The core challenge is not the lack of available tools, but the absence of **cognitive coordination across tools**. Students must manually extract, prioritize, and act upon information scattered across:
- Canvas assignment deadlines
- Google Calendar events
- Course difficulty information
- Internship timelines
- Campus mental health resources
- Budget and life logistics platforms

This integration burden is particularly severe for vulnerable populations: international students navigating unfamiliar academic norms, first-generation students lacking inherited institutional strategies, students with ADHD or executive function difficulties, financially constrained students optimizing under pressure, and incoming freshmen adjusting to new environments.

### Multi-Role Agentic Architecture

Rather than deploying a single monolithic chatbot, ORBIT constructs a dynamic ecosystem of specialized AI roles, each composed of modular agent skills that are activated based on user-specific labels and behavioral state signals.

#### Agent Skills as Compositional Units

A key architectural innovation is the formalization of **Agent Skills** as structured computational units, each consisting of:
- Constrained prompt templates
- Optional retrieval components
- Explicit tool or API access
- Structured output schemas

Skills are invoked deterministically by a workflow controller and produce intermediate structured outputs rather than free-form dialogue. This provides:
- **Modularity**: Complex reasoning emerges from compositional units
- **Interpretability**: Intermediate outputs are structured and traceable
- **Efficiency**: Lightweight models handle classification; large models handle strategic reasoning
- **Debuggability**: Skills can be tested independently

For example, the Academic Planning Role orchestrates:
- Deadline Extraction Skill (Canvas API integration)
- Calendar Density Analysis Skill (Google Calendar integration)
- Priority Scoring Skill (structured urgency computation)
- Task Redistribution Skill (schedule restructuring)

The Stress Monitoring Role orchestrates:
- Mood Classification Skill
- Workload Spike Detection Skill
- Baseline Deviation Skill
- Risk Aggregation Skill

### Label-Driven Personalization

Unlike superficial personalization systems that modify tone or language style, ORBIT uses **labelization as structural configuration**. Labels influence which roles are activated and which skills are prioritized:

| User Label | Activated Roles | Priority Focus |
|------------|-----------------|-----------------|
| International + Incoming | Campus Navigation, Life Logistics | Resource discovery and administrative guidance |
| ADHD + STEM Major | Academic Planning, Focus Optimization | Deadline prioritization and task restructuring |
| Financial Stress | Budget Optimization, Career Roadmap | Cost-efficient decisions and income planning |
| Pre-Internship Year | Career Strategy, Course Balancing | Timeline simulation and workload projection |

Labelization is dynamic rather than static. The system continuously updates user state based on:
- Canvas deadline density
- Google Calendar occupancy ratio
- Optional screen-time summaries
- Weekly or daily mood self-reports

As workload intensifies or stress risk increases, role weights are recalibrated and skill invocation thresholds are adjusted.

### Contextual Behavioral Integration

ORBIT integrates structured and behavioral data streams to assess student state holistically:
- Canvas assignment and exam metadata
- Google Calendar event density
- Optional screen-time summaries
- Periodic self-reported mood indicators

The purpose is contextual reasoning, not surveillance. For instance, when a student completes a high-stress exam and the system detects temporary calendar density reduction, if the student's profile includes health-conscious preferences, the mobile app may recommend a short campus walking route or balanced meal option aligned with dietary goals.

### Workflow-Oriented Orchestration

All role collaboration and skill invocation are governed by a deterministic workflow controller. Outputs flow through defined pipelines such as:

```
Deadline Extraction → Density Analysis → Stress Projection → Intervention Selection → Resource Connection
```

This approach avoids uncontrolled conversational loops, reduces token inefficiency, and ensures recommendations are traceable to specific reasoning stages.

### Stress Modeling and Visualization

Stress monitoring operates continuously rather than exclusively on weekly intervals. A composite Stress Risk Score is computed using:
- Workload clustering
- Calendar saturation
- Baseline deviation
- Mood signals

Data visualization is treated as an integral reasoning component rather than an auxiliary interface. The web dashboard presents:
- Stress timeline graphs
- Deadline density heatmaps
- Weekly workload distributions
- Stress source breakdown by category

Visualization outputs are summarized into machine-readable states that influence future skill invocation thresholds. Rising stress trajectories may trigger earlier intervention, while stable periods may reduce notification frequency.

### Chat Flow

1. User enters message and selects optional recommendation
2. `ChatProvider` captures message, labels, and context
3. `OrbitAgentOrchestrator` routes to appropriate role agents
4. Each agent produces deterministic skill outputs
5. `StudentContextAggregator` fetches optional real-data snapshot
6. Adaptive runtime skill is synthesized from labels and data
7. `OllamaLocalLlmClient` generates final response (if model available)
8. Fallback logic uses agent skills if synthesis unavailable
9. Response and conversation state saved to Hive

### Label System
- **Onboarding Labels**: `college_student`, `academic_planning`, `stress_sensitive`, `career_builder`, `life_logistics`, `local_first`
- **Support Labels**: `planning`, `writing`, `study_help`, `summarization`, `image_analysis`, `wellbeing_checkin`
- **Profile Labels**: `vegan`, `plant_based`, `commuter`, `campus_navigation`, `movement_breaks`, `google_calendar`, `canvas`

Labels are extracted from:
1. Initial onboarding intake questions
2. Recent chat history (conversation analysis)
3. User profile preferences
4. Real-data signal inference (calendar density, deadline proximity, etc.)

## 🐛 Troubleshooting

### App Won't Start
```bash
# Clean build artifacts
flutter clean

# Reinstall dependencies
flutter pub get

# Run with verbose output
flutter run -v
```

### Hive Database Errors
```dart
// In main.dart, Hive needs type adapter registration
// Check ChatProvider.initHive() is called before runApp()
```

### API Connection Issues
- **Canvas**: Verify `CANVAS_BASE_URL` and `CANVAS_ACCESS_TOKEN`
- **Google**: Check API key and enable required Google APIs
- **Ollama**: Run `ollama serve` separately
- **Student Data Proxy**: Run backend in separate terminal

### Speech-to-Text Not Working
- **Android**: Check microphone permission in app settings
- **iOS**: Add `NSMicrophoneUsageDescription` to Info.plist
- **Web**: Requires HTTPS or localhost

## 📖 Documentation

Additional documentation is available in the `docs/` folder:
- [Local Multi-Agent System Architecture](docs/local-multi-agent-system.md)
- [Student Data Proxy Backend Setup](backend/student-data-proxy/README.md)
- [Recommendation Skill Router Plan](docs/recommendation-skill-router-plan.md)

## 🤝 Contributing

1. Create a feature branch
2. Run tests and linting
   ```bash
   flutter analyze
   flutter test
   ```
3. Format code
   ```bash
   dart format lib/ test/
   ```
4. Submit pull request with description

## 📄 License

See [LICENSE](LICENSE) file for details.

## 👥 Support

For issues and questions:
1. Check existing documentation in `docs/`
2. Review backend setup in `backend/student-data-proxy/`
3. Open an issue with detailed reproduction steps

---

**Built with Flutter • Powered by ORBIT • Privacy-First, Skill-Compositional Design**
