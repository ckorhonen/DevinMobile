# Devin API Migration Guide: v1 → v3

This guide covers migrating the DevinMobile iOS app from the v1 API to v3. The v1 API is deprecated and will eventually be removed. All new features are v3-only.

---

## Summary of Breaking Changes

| Aspect | v1 | v3 | Impact |
|--------|----|----|--------|
| **Auth** | `apk_user_*` / `apk_*` | `cog_*` (service user) | New credential type, RBAC permissions |
| **Base URL** | `/v1/*` | `/v3/organizations/{org_id}/*` | Org ID required in all paths |
| **Pagination** | `limit`/`offset` | `first`/`after` cursor-based | Different request/response model |
| **Timestamps** | ISO 8601 strings | Unix integers | Date parsing changes |
| **Session status** | `status_enum` (flat) | `status` + `status_detail` (two-level) | Status mapping changes |
| **Messages** | Inline in session GET | Separate `/messages` endpoint | Extra API call needed |
| **Send message path** | `/message` (singular) | `/messages` (plural) | Path change |
| **Pull requests** | `{ url, title, number }` | `[{ pr_url, pr_state }]` (array) | Different field names, now an array |
| **Knowledge trigger** | `trigger_description` | `trigger` | Field rename |
| **Secret response** | `id`, `type` | `secret_id`, `secret_type` | Field rename |

---

## 1. Authentication Migration

### Current (v1)
```swift
// KeychainService stores an apk_user_* or apk_* token
let token = try KeychainService.getAPIKey()
// Used as: Authorization: Bearer {token}
```

### Target (v3)
```swift
// KeychainService stores a cog_* service user token
// Also need to store the org_id for URL construction
let token = try KeychainService.getAPIKey()
let orgId = try KeychainService.getOrgId()  // NEW
```

**Migration steps**:
1. Add `orgId` storage to `KeychainService`
2. Update `APIKeySetupView` to collect/resolve the org ID
3. Consider using `GET /v3/enterprise/self` to discover the `org_id` from the token
4. Support both `apk_*` (v1) and `cog_*` (v3) tokens during transition

---

## 2. Base URL & Endpoint Migration

### APIConfiguration changes

```swift
// Current
static let baseURL = "https://api.devin.ai/v1"

// Target — need org_id for most endpoints
static let orgBaseURL = "https://api.devin.ai/v3/organizations/{org_id}"
static let enterpriseBaseURL = "https://api.devin.ai/v3/enterprise"
```

### Endpoint mapping

| v1 Path | v3 Path | Notes |
|---------|---------|-------|
| `GET /v1/sessions` | `GET /v3/organizations/{org_id}/sessions` | Different pagination |
| `POST /v1/sessions` | `POST /v3/organizations/{org_id}/sessions` | New fields available |
| `GET /v1/sessions/{id}` | `GET /v3/organizations/{org_id}/sessions/{id}` | Messages not inline |
| `DELETE /v1/sessions/{id}` | `DELETE /v3/organizations/{org_id}/sessions/{id}` | |
| `POST /v1/sessions/{id}/message` | `POST /v3/organizations/{org_id}/sessions/{id}/messages` | Plural path |
| `GET /v1/knowledge` | `GET /v3/organizations/{org_id}/knowledge/notes` | Different path |
| `POST /v1/knowledge` | `POST /v3/organizations/{org_id}/knowledge/notes` | `trigger` not `trigger_description` |
| `PUT /v1/knowledge/{id}` | `PUT /v3/organizations/{org_id}/knowledge/notes/{id}` | |
| `DELETE /v1/knowledge/{id}` | `DELETE /v3/organizations/{org_id}/knowledge/notes/{id}` | |
| `GET /v1/playbooks` | `GET /v3/organizations/{org_id}/playbooks` | |
| `POST /v1/playbooks` | `POST /v3/organizations/{org_id}/playbooks` | |
| `GET /v1/playbooks/{id}` | `GET /v3/organizations/{org_id}/playbooks/{id}` | |
| `PUT /v1/playbooks/{id}` | `PUT /v3/organizations/{org_id}/playbooks/{id}` | |
| `DELETE /v1/playbooks/{id}` | `DELETE /v3/organizations/{org_id}/playbooks/{id}` | |
| `GET /v1/secrets` | `GET /v3/organizations/{org_id}/secrets` | |
| `POST /v1/secrets` | `POST /v3/organizations/{org_id}/secrets` | |
| `DELETE /v1/secrets/{id}` | `DELETE /v3/organizations/{org_id}/secrets/{id}` | |
| `GET /v1/enterprise/consumption` | `GET /v3/enterprise/consumption/daily` | More granular options |

---

## 3. Pagination Migration

### Current (v1) — Offset-based

```swift
// APIEndpoint
case listSessions(limit: Int? = nil, offset: Int? = nil, userEmail: String? = nil)

// Usage
var queryItems: [URLQueryItem] = []
if let limit { queryItems.append(.init(name: "limit", value: "\(limit)")) }
if let offset { queryItems.append(.init(name: "offset", value: "\(offset)")) }
```

### Target (v3) — Cursor-based

```swift
case listSessions(first: Int? = nil, after: String? = nil, ...)

// Usage
var queryItems: [URLQueryItem] = []
if let first { queryItems.append(.init(name: "first", value: "\(first)")) }
if let after { queryItems.append(.init(name: "after", value: after)) }
```

**Response model change**:

```swift
// Current: SessionListResponse
struct SessionListResponse: Decodable, Sendable {
    let sessions: [Session]
}

// Target: PaginatedResponse<Session>
struct PaginatedResponse<T: Decodable & Sendable>: Decodable, Sendable {
    let items: [T]
    let hasNextPage: Bool
    let endCursor: String?
    let total: Int?
}
```

> **Note**: The app already defines a `PaginatedResponse<T>` model but doesn't use it yet. This was clearly designed for the v3 migration.

---

## 4. Timestamp Migration

### Current (v1)
```swift
// ISO 8601 strings: "2025-01-15T10:30:00Z"
// Parsed with Date.fromISO8601(_:)
let createdAt: String?
```

### Target (v3)
```swift
// Unix timestamps: 1705312200
let createdAt: Int  // Unix seconds
```

**Migration**:
- Add a `Date` extension for Unix timestamp conversion
- Update all model `createdAt`/`updatedAt` fields from `String?` to `Int`
- Update date display helpers

---

## 5. Session Status Migration

### Current (v1)
```swift
enum SessionStatus: String, Codable {
    case running, working, blocked, stopped, finished, expired
    case suspendRequested = "suspend_requested"
    case suspendRequestedFrontend = "suspend_requested_frontend"
    case resumeRequested = "resume_requested"
    case resumeRequestedFrontend = "resume_requested_frontend"
    case resumed
}
```

### Target (v3)
```swift
enum SessionStatus: String, Codable {
    case new, claimed, running, exit, error, suspended, resuming
}

enum SessionStatusDetail: String, Codable {
    // Running details
    case working
    case waitingForUser = "waiting_for_user"
    case waitingForApproval = "waiting_for_approval"
    case finished
    // Suspended details
    case inactivity
    case userRequest = "user_request"
    case usageLimitExceeded = "usage_limit_exceeded"
    case outOfCredits = "out_of_credits"
    case paymentDeclined = "payment_declined"
    case orgUsageLimitExceeded = "org_usage_limit_exceeded"
    case error
}
```

**Status mapping** (v1 → v3):

| v1 `status_enum` | v3 `status` | v3 `status_detail` |
|-------------------|-------------|---------------------|
| `working` | `running` | `working` |
| `blocked` | `running` | `waiting_for_user` |
| `finished` | `exit` | — |
| `expired` | `suspended` | `inactivity` |
| `suspend_requested` | `suspended` | `user_request` |
| `resume_requested` | `resuming` | — |

---

## 6. Session Messages Migration

### Current (v1)
Messages are returned inline when fetching a session:
```swift
// GET /v1/sessions/{id} returns messages in response body
let response: SessionDetailResponse = try await APIClient.shared.perform(.getSession(id: id))
let messages = response.messages ?? []
```

### Target (v3)
Messages are a separate sub-resource:
```swift
// GET /v3/organizations/{org_id}/sessions/{id} — no messages
let session: SessionResponse = try await APIClient.shared.perform(.getSession(id: id))

// GET /v3/organizations/{org_id}/sessions/{id}/messages — separate call
let messages: PaginatedResponse<SessionMessage> = try await APIClient.shared.perform(.getSessionMessages(id: id))
```

---

## 7. Pull Request Model Migration

### Current (v1)
```swift
struct PullRequest: Codable, Sendable {
    let url: String?
    let title: String?
    let number: Int?
}
// Single optional PR per session
let pullRequest: PullRequest?
```

### Target (v3)
```swift
struct SessionPullRequest: Codable, Sendable {
    let prUrl: String
    let prState: String?  // open, closed, merged
}
// Array of PRs per session
let pullRequests: [SessionPullRequest]
```

---

## 8. Knowledge Model Migration

### Current (v1)
```swift
struct KnowledgeNote: Codable {
    let noteId: String?
    let name: String
    let body: String
    let triggerDescription: String?  // v1 field name
    let trigger: String?
    // ...
}
```

### Target (v3)
```swift
struct KnowledgeNote: Codable {
    let noteId: String
    let name: String
    let body: String
    let trigger: String  // v3 field name (was trigger_description in v1)
    let isEnabled: Bool
    let accessType: String  // "enterprise" or "org"
    // ...
}
```

---

## 9. New v3-Only Features to Adopt

These features don't exist in v1 and can be added as new functionality:

| Feature | Endpoint | Value for Mobile App |
|---------|----------|---------------------|
| **Session Insights** | `GET .../sessions/{id}/insights` | AI analysis, classification, timeline |
| **Advanced Modes** | `advanced_mode` in create | analyze, create, improve, batch, manage |
| **Session Archive** | `POST .../sessions/{id}/archive` | Better session management |
| **Schedules** | `GET/POST .../schedules` | Recurring task management |
| **Session Origins** | `origins` filter on list | Filter by source (api, slack, webapp) |
| **Queue Health** | `GET /v3/enterprise/queue` | Show queue status in settings |
| **Granular Consumption** | Per-user, per-session, by-product | Detailed usage analytics |
| **Searches** | `GET .../searches` | View Devin search history |

---

## Recommended Migration Order

1. **Add org_id storage** — KeychainService, AuthGate, APIKeySetupView
2. **Update APIConfiguration** — support both v1 and v3 base URLs
3. **Migrate APIEndpoint** — update paths, add org_id parameter
4. **Migrate pagination** — activate `PaginatedResponse<T>`, update ViewModels
5. **Migrate models** — timestamps, status enums, field renames
6. **Migrate sessions** — separate messages fetch, pull request array
7. **Add new features** — insights, schedules, archive, advanced modes
8. **Remove v1 support** — once v3 is stable, remove v1 code paths
