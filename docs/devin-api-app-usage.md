# Devin API: App Usage & Recommendations

How each Devin API endpoint maps to the DevinMobile iOS app — what's implemented, what's missing, and what to adopt.

---

## Currently Implemented (v1)

The app currently uses 18 endpoint cases, all on v1:

### Sessions (5 endpoints)

| Endpoint | App Usage | ViewModel |
|----------|-----------|-----------|
| `GET /v1/sessions` | Sessions list tab, pull-to-refresh, offset pagination | `SessionListViewModel` |
| `POST /v1/sessions` | "New Session" flow with prompt, optional playbook/title/ACU limit | `CreateSessionViewModel` |
| `GET /v1/sessions/{id}` | Session detail view — shows messages inline, PR link, status | `SessionDetailViewModel` |
| `DELETE /v1/sessions/{id}` | Terminate button on session detail | `SessionDetailViewModel` |
| `POST /v1/sessions/{id}/message` | Chat input on session detail | `SessionDetailViewModel` |

### Knowledge (4 endpoints)

| Endpoint | App Usage | ViewModel |
|----------|-----------|-----------|
| `GET /v1/knowledge` | Knowledge tab list view | `KnowledgeListViewModel` |
| `POST /v1/knowledge` | Create note sheet | `KnowledgeListViewModel` |
| `PUT /v1/knowledge/{id}` | Edit note view | `KnowledgeListViewModel` |
| `DELETE /v1/knowledge/{id}` | Swipe-to-delete | `KnowledgeListViewModel` |

### Playbooks (5 endpoints)

| Endpoint | App Usage | ViewModel |
|----------|-----------|-----------|
| `GET /v1/playbooks` | Playbooks tab list, also used in session creation picker | `PlaybookListViewModel` |
| `POST /v1/playbooks` | Create playbook sheet | `PlaybookListViewModel` |
| `GET /v1/playbooks/{id}` | Playbook detail view | `PlaybookDetailViewModel` |
| `PUT /v1/playbooks/{id}` | Edit playbook | `PlaybookDetailViewModel` |
| `DELETE /v1/playbooks/{id}` | Swipe-to-delete | `PlaybookListViewModel` |

### Secrets (3 endpoints)

| Endpoint | App Usage | ViewModel |
|----------|-----------|-----------|
| `GET /v1/secrets` | Settings → Secrets list | `SecretsViewModel` |
| `POST /v1/secrets` | Add secret sheet | `SecretsViewModel` |
| `DELETE /v1/secrets/{id}` | Swipe-to-delete | `SecretsViewModel` |

### Enterprise (1 endpoint)

| Endpoint | App Usage | ViewModel |
|----------|-----------|-----------|
| `GET /v1/enterprise/consumption` | Settings → Usage chart (Charts framework) | `ConsumptionViewModel` |

---

## Not Yet Implemented (Available in v1)

These v1 endpoints exist but aren't used in the app:

| Endpoint | Potential Use |
|----------|--------------|
| `POST /v1/attachments` | Allow users to upload files when creating sessions or sending messages |
| `GET /v1/attachments/{uuid}/{name}` | View/download attachments from session messages |
| `GET /v1/sessions/{id}/attachments` | Show attachment list in session detail |
| `PUT /v1/sessions/{id}/tags` | Tag management on sessions |

**Recommendation**: Attachments and tags are useful mobile features. Consider adding them during or after the v3 migration.

---

## Unused Models in Codebase

| Model | File | Notes |
|-------|------|-------|
| `SelfResponse` | `Models/SelfResponse.swift` | No `/self` endpoint wired up — will be needed for v3 |
| `ArchiveSessionRequest` | `Models/Session.swift` | No archive endpoint — v3 adds this |
| `PaginatedResponse<T>` | `Models/PaginatedResponse.swift` | Built for v3 cursor pagination, not used with v1 |

---

## High-Value v3-Only Features to Adopt

### Tier 1 — Core Improvements

| Feature | v3 Endpoint | Why It Matters |
|---------|-------------|---------------|
| **Session Insights** | `GET .../sessions/{id}/insights` | AI-powered session analysis with classification, issues, action items, timeline. Could power a rich session summary view. |
| **Session Archive** | `POST .../sessions/{id}/archive` | Let users archive completed sessions instead of only deleting them. |
| **Separate Messages** | `GET .../sessions/{id}/messages` | Paginated message history — better for long sessions with many messages. |
| **Two-Level Status** | `status` + `status_detail` | Much richer status display — show "Waiting for user" vs "Working" vs "Out of credits" |

### Tier 2 — New Functionality

| Feature | v3 Endpoint | Why It Matters |
|---------|-------------|---------------|
| **Schedules** | `GET/POST .../schedules` | Create and manage recurring Devin tasks from mobile. New tab or settings section. |
| **Advanced Modes** | `advanced_mode` in create | Let users choose analyze/create/improve/batch/manage when starting sessions. |
| **Session Origins Filter** | `origins` query param | Filter sessions by source — see only API-created vs Slack vs webapp sessions. |
| **Granular Consumption** | Per-user, per-session, by-product | Break down usage by Devin/Cascade/Terminal. Per-session cost tracking. |

### Tier 3 — Power User / Admin

| Feature | v3 Endpoint | Why It Matters |
|---------|-------------|---------------|
| **Queue Health** | `GET /v3/enterprise/queue` | Show queue status indicator in the app — are sessions waiting? |
| **Searches** | `GET .../searches` | View Devin search history |
| **Metrics Dashboard** | `GET /v3/enterprise/metrics/*` | DAU/WAU/MAU, PR metrics, session metrics for org admins |
| **Audit Logs** | `GET .../audit-logs` | Enterprise compliance viewing |
| **User/Member Mgmt** | `GET/POST .../members/users` | Admin-level user management from mobile |

---

## Recommended New Views/Features

### Session Insights View
**Endpoints**: `GET /v3/.../sessions/{id}/insights`

Display AI analysis of completed sessions:
- Classification (category, languages, frameworks)
- Issue list with impact assessment
- Action items
- Visual timeline
- Prompt improvement suggestions

### Schedules Tab
**Endpoints**: `GET/POST/PATCH/DELETE /v3/.../schedules`

New tab or settings section for managing recurring tasks:
- List scheduled sessions with frequency
- Create new schedules (name, prompt, frequency, agent type)
- Edit/delete schedules
- View sessions spawned by a schedule

### Enhanced Consumption View
**Endpoints**: `GET /v3/enterprise/consumption/daily`, `/daily/users/{id}`, `/daily/sessions/{id}`

Upgrade the existing consumption chart:
- Break down by product (Devin, Cascade, Terminal)
- Per-session cost view
- Per-user consumption (for admins)
- Consumption cycles with billing periods

### Session Tags Management
**Endpoints**: `GET/POST/PUT .../sessions/{id}/tags`, `GET/POST .../tags`

- Tag picker when creating sessions
- Filter session list by tags
- Manage allowed org tags

---

## API Feature Comparison Table

| Feature | v1 (Current) | v3 (Target) | Improvement |
|---------|:---:|:---:|---|
| Session CRUD | ✓ | ✓ | + archive, + advanced modes |
| Messages | Inline | Separate + paginated | Better for long sessions |
| Session Status | 8 flat values | 7 + 11 detail values | Much richer status info |
| Pull Requests | Single, optional | Array with state | Multiple PRs, track merge status |
| Knowledge CRUD | ✓ | ✓ | + `is_enabled` toggle, + access_type |
| Playbooks CRUD | ✓ | ✓ | + access_type (enterprise/org) |
| Secrets CRUD | ✓ | ✓ | + `created_by` attribution |
| Attachments | Available (not used) | ✓ | Same functionality |
| Session Insights | — | ✓ | AI analysis, timeline, classifications |
| Schedules | — | ✓ | Recurring task management |
| Tags | Available (not used) | ✓ (expanded) | Org-level tag management |
| Consumption | Basic total | By product/user/session | Granular usage analytics |
| Searches | — | ✓ | Search history |
| Queue Health | — | ✓ | Queue status monitoring |
| Pagination | Offset | Cursor | More reliable for large datasets |

---

## Migration Priority Matrix

| Priority | Action | Effort | Value |
|----------|--------|--------|-------|
| **P0** | Auth + org_id migration | Medium | Required for v3 |
| **P0** | Base URL + endpoint paths | Medium | Required for v3 |
| **P0** | Pagination model (cursor) | Medium | Required for v3 |
| **P1** | Timestamp format migration | Low | Correctness |
| **P1** | Status model migration | Medium | Better UX |
| **P1** | Separate messages endpoint | Medium | Better performance |
| **P1** | Pull request array model | Low | Data completeness |
| **P2** | Session insights view | High | High-value new feature |
| **P2** | Session archive | Low | Better session management |
| **P2** | Advanced session modes | Medium | Power user feature |
| **P3** | Schedules tab | High | New functionality |
| **P3** | Enhanced consumption | Medium | Better analytics |
| **P3** | Tags management | Medium | Organization feature |
| **P4** | Queue health indicator | Low | Nice to have |
| **P4** | Searches view | Medium | Nice to have |
| **P4** | Admin features | High | Niche audience |
