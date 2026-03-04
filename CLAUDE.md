# DevinMobile

iOS client for the [Devin AI API](https://api.devin.ai/v1). Manages sessions, knowledge notes, playbooks, secrets, and ACU consumption.

## Build & Run

- Open `DevinMobile.xcodeproj` in Xcode
- Requires Xcode 16.2+, iOS 26.0 deployment target
- No external dependencies — uses only Apple frameworks (SwiftUI, Foundation, Security, Charts, FoundationModels)
- Build: `xcodebuild -project DevinMobile.xcodeproj -scheme DevinMobile -sdk iphonesimulator build`
- No test target currently exists

## Architecture

**MVVM with Swift Observation framework** — no Combine, no UIKit.

- **Models** (`DevinMobile/Models/`): Plain `Codable`, `Sendable` structs/enums
- **ViewModels** (`DevinMobile/ViewModels/`): `@Observable @MainActor final class` — one per screen
- **Views** (`DevinMobile/Views/`): Pure SwiftUI, organized by feature (Sessions/, Knowledge/, Playbooks/, Settings/, Components/)
- **Networking** (`DevinMobile/Networking/`): `APIClient` is an `actor` singleton. `APIEndpoint` enum defines all routes. `RequestBuilder` constructs requests.
- **Services** (`DevinMobile/Services/`): `KeychainService` wraps Security framework for token/credential storage. `FoundationModelService` wraps Apple's on-device LLM for AI features.

**App flow:** `DevinMobileApp` → `AuthGate` (checks keychain for API key) → `APIKeySetupView` or `RootView` (TabView with 4 tabs)

## Code Conventions

- **Swift 6.0** with `SWIFT_STRICT_CONCURRENCY = complete` — all code must be concurrency-safe
- All ViewModels: `@Observable @MainActor final class`
- All models: `Codable`, `Sendable` (and `Identifiable`, `Hashable` where needed)
- Use `LoadingState<T>` enum (idle/loading/loaded/error) for async state in ViewModels
- Use `ErrorInfo` to wrap errors with message, systemImage, and actionLabel
- API calls go through `APIClient.shared.perform<T>()` or `performVoid()` — never call URLSession directly
- JSON uses snake_case keys (decoder: `.convertFromSnakeCase`, encoder: `.convertToSnakeCase`)
- Dates come as ISO 8601 strings — parse with `Date.fromISO8601(_:)`, format with `String.asRelativeDate`
- Brand colors defined in `Color+Devin.swift` (devinGreen, devinYellow, devinBlue, devinGray, devinRed, devinOrange)
- Navigation uses `NavigationStack` with `navigationDestination(for:)`
- No third-party dependencies — keep it that way unless explicitly discussed
- On-device AI uses Apple `FoundationModels` framework with `@Generable` structs/enums for typed output
- AI features must check `FoundationModelService.shared.isAvailable` and gracefully hide when unavailable
- AI results are cached in `CachedSession` (`generatedCategory`, `generatedSummary`) — local-only, not overwritten by API refreshes

## Key Files

| Purpose | File |
|---------|------|
| App entry | `DevinMobile/App/DevinMobileApp.swift` |
| Auth gate | `DevinMobile/App/AuthGate.swift` |
| Tab bar | `DevinMobile/App/RootView.swift` |
| API client | `DevinMobile/Networking/APIClient.swift` |
| API endpoints | `DevinMobile/Networking/APIEndpoint.swift` |
| Request builder | `DevinMobile/Networking/RequestBuilder.swift` |
| Keychain | `DevinMobile/Services/KeychainService.swift` |
| Loading state | `DevinMobile/ViewModels/LoadingState.swift` |
| Brand colors | `DevinMobile/Extensions/Color+Devin.swift` |
| Date helpers | `DevinMobile/Extensions/Date+Formatting.swift` |
| Foundation model service | `DevinMobile/Services/FoundationModelService.swift` |
| Session category model | `DevinMobile/Models/SessionCategory.swift` |
| Session summary model | `DevinMobile/Models/SessionSummary.swift` |
| Knowledge note draft model | `DevinMobile/Models/KnowledgeNoteDraft.swift` |

## Adding a New Feature

1. Add API endpoint case to `APIEndpoint` enum
2. Add model structs in `Models/`
3. Create ViewModel in `ViewModels/` following `@Observable @MainActor final class` pattern with `LoadingState<T>`
4. Create View in `Views/<Feature>/`
5. Wire into navigation from `RootView` or parent view
