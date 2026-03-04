<p align="center">
  <img src="DevinMobile/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="128" height="128" alt="Devin Mobile app icon" style="border-radius: 22%;">
</p>

<h1 align="center">Devin Mobile</h1>

<p align="center">
  A native iOS client for <a href="https://devin.ai">Devin</a>, the AI software engineer by Cognition
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS_26+-blue?logo=apple" alt="iOS 26+">
  <img src="https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&logoColor=white" alt="Swift 6.0">
  <img src="https://img.shields.io/badge/Xcode-16.2+-1575F9?logo=xcode&logoColor=white" alt="Xcode 16.2+">
  <img src="https://img.shields.io/badge/dependencies-none-brightgreen" alt="Zero dependencies">
  <img src="https://img.shields.io/badge/license-MIT-lightgrey" alt="MIT License">
  <img src="https://img.shields.io/badge/TestFlight-coming_soon-informational?logo=apple" alt="TestFlight coming soon">
</p>

---

Monitor sessions, message Devin, manage knowledge and playbooks, review PRs, and track usage — all from your phone. Built entirely with SwiftUI and Apple frameworks. No third-party dependencies.

## Features

**Sessions**
- Browse, filter, and search active sessions with status and repo filters
- Start new sessions with optional playbook selection
- Real-time conversation view with markdown rendering and code blocks
- Send follow-up messages with file and photo attachments (up to 5)
- Swipe to archive/unarchive sessions
- Auto-polling (30s list, 10s detail) with background-aware lifecycle

**Pull Requests**
- PR state badges (open/merged/closed) on session rows
- Filter sessions by repository
- Deep link to GitHub app or Safari

**On-Device AI** (Apple Foundation Models)
- Auto-generated session category tags (bug, feature, refactor, performance, docs, infra, question)
- AI-powered 1–2 sentence session summaries shown in session detail
- One-tap knowledge note drafting from completed sessions — extracts reusable patterns and instructions
- All processing on-device, offline-capable, no API costs
- Gracefully hidden on devices without Apple Intelligence

**Knowledge & Playbooks**
- Create, edit, and delete knowledge notes with triggers
- Browse and run playbooks to start pre-configured sessions

**Organization**
- View and manage secrets
- ACU consumption dashboard with daily bar chart (enterprise) or per-session breakdown (personal)

**Technical**
- MVVM with Swift Observation (`@Observable`) — no Combine, no UIKit
- Strict concurrency (`SWIFT_STRICT_CONCURRENCY = complete`)
- SwiftData persistence with offline cache and smart staleness checks
- Devin API v1 + v3 beta with automatic version negotiation
- iOS 26 liquid glass tab bar
- Generative per-session header backgrounds seeded from session ID
- On-device AI via Apple Foundation Models (`@Generable` structured output, cached in SwiftData)

## Requirements

| Requirement | Version |
|-------------|---------|
| iOS | 26.0+ |
| Xcode | 16.2+ |
| Swift | 6.0 |

A [Devin API key](https://app.devin.ai/settings/api-keys) is required to use the app.

## Getting Started

1. Clone the repo:
   ```bash
   git clone https://github.com/anthropics/devin-mobile.git
   cd devin-mobile
   ```

2. Copy the config templates:
   ```bash
   cp .env.example .env
   cp Local.xcconfig.example Local.xcconfig
   ```

3. Fill in your values:
   - **`Local.xcconfig`** — set your Apple Developer Team ID and bundle identifier
   - **`.env`** — set your App Store Connect API credentials (only needed for TestFlight uploads)

4. Open `DevinMobile.xcodeproj` in Xcode and run on a simulator or device.

5. On first launch, enter your Devin API key and email to connect.

## Project Structure

```
DevinMobile/
├── App/                    # App entry point, AuthGate, RootView (tab bar)
├── Models/                 # Codable structs (Session, Message, Knowledge, etc.)
├── ViewModels/             # @Observable @MainActor view models with LoadingState<T>
├── Views/
│   ├── Sessions/           # Session list, detail, composer, search
│   ├── Knowledge/          # Knowledge notes CRUD
│   ├── Playbooks/          # Playbook list, detail, run sheet
│   ├── Settings/           # Settings, secrets, consumption, API key setup
│   └── Components/         # Shared UI (StatusBadge, FilterChips, Toast, etc.)
├── Networking/             # APIClient actor, APIEndpoint enum, RequestBuilder
├── Services/               # KeychainService, FoundationModelService (on-device AI)
├── Persistence/            # SwiftData models and ModelContainer setup
└── Extensions/             # Color+Devin, Date+Formatting, String helpers
```

## Architecture

The app follows **MVVM** with Swift's Observation framework:

- **Models** are plain `Codable`, `Sendable` structs
- **ViewModels** are `@Observable @MainActor final class` with `LoadingState<T>` for async state
- **Views** are pure SwiftUI, organized by feature
- **APIClient** is a Swift `actor` singleton — all networking goes through `perform<T>()` or `performVoid()`
- **KeychainService** wraps the Security framework for credential storage
- **FoundationModelService** is a Swift `actor` wrapping Apple's on-device LLM for session categorization, summarization, and knowledge extraction. Results are cached in SwiftData and persist across API refreshes.

## TestFlight Upload

The `scripts/upload_testflight.sh` script reads credentials from `.env`:

```bash
./scripts/upload_testflight.sh              # uses default IPA path
./scripts/upload_testflight.sh /path/to.ipa # custom IPA path
```

## License

MIT
