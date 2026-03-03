# Devin API Overview

The Devin AI platform exposes a REST API at `https://api.devin.ai` across three major versions. This document provides a high-level comparison and links to detailed per-version references.

## API Versions at a Glance

| | v1 (Legacy) | v2 (Legacy) | v3 (Current) |
|---|---|---|---|
| **Base URL** | `/v1/*` | `/v2/enterprise/*` | `/v3/organizations/{org_id}/*` and `/v3/enterprise/*` |
| **Status** | Deprecated — no new features | Deprecated — no new features | **GA — all new development here** |
| **Auth** | Personal API keys (`apk_user_*`) or Service API keys (`apk_*`) | Enterprise Admin personal keys only | Service User credentials (`cog_*`) |
| **RBAC** | None | None | Full per-endpoint permissions |
| **Pagination** | Offset-based (`limit`/`offset`) | Offset-based (max 200/page) | Cursor-based (`first`/`after`/`end_cursor`/`has_next_page`) |
| **Timestamps** | ISO 8601 strings | Mixed | Unix integers |
| **Scope** | Single org | Enterprise-wide | Both org-scoped and enterprise-scoped |
| **Session Status** | `status_enum` (8 values) | N/A | `status` (7 values) + `status_detail` (11 values) |
| **Target Users** | Individual developers | Enterprise admins | All users (org + enterprise) |

## Authentication

### v1 — API Keys
```
Authorization: Bearer apk_user_xxxxx   (personal key)
Authorization: Bearer apk_xxxxx        (service key)
```
Keys are scoped to an `(org_id, user_id)` pair. No RBAC — if you have a key, you have full access within that org.

### v2 — Enterprise Admin Keys
```
Authorization: Bearer apk_user_xxxxx   (must have Enterprise Admin role)
```
Service API keys and org-level keys are **not** accepted. Only personal keys belonging to Enterprise Admins work.

### v3 — Service User Credentials
```
Authorization: Bearer cog_xxxxx
```
Service users are provisioned via the API and scoped to either a single org or the entire enterprise. Every endpoint is gated by specific RBAC permissions (e.g., `ViewOrgSessions`, `ManageOrgSecrets`, `ManageBilling`).

## Common HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 204 | No Content (successful delete) |
| 400 | Bad request / validation error |
| 401 | Unauthorized — invalid or expired key |
| 403 | Forbidden — insufficient permissions |
| 404 | Not found |
| 422 | Validation error (detailed) |
| 429 | Rate limited |
| 500 | Server error |

## Pagination Styles

### v1/v2 — Offset-Based
```
GET /v1/sessions?limit=100&offset=0
```

### v3 — Cursor-Based
```
GET /v3/organizations/{org_id}/sessions?first=100&after=cursor_abc
```
Response:
```json
{
  "items": [...],
  "end_cursor": "cursor_xyz",
  "has_next_page": true,
  "total": 500
}
```

## Session Status Models

### v1 `status_enum`
`working` | `blocked` | `expired` | `finished` | `suspend_requested` | `suspend_requested_frontend` | `resume_requested` | `resume_requested_frontend` | `resumed`

### v3 Two-Level Status
**`status`**: `new` | `claimed` | `running` | `exit` | `error` | `suspended` | `resuming`

**`status_detail`** (contextual):
- While running: `working` | `waiting_for_user` | `waiting_for_approval` | `finished`
- While suspended: `inactivity` | `user_request` | `usage_limit_exceeded` | `out_of_credits` | `payment_declined` | `org_usage_limit_exceeded` | `error`

## Endpoint Coverage by Version

| Resource | v1 | v2 | v3 |
|----------|:--:|:--:|:--:|
| Sessions (CRUD + messaging) | ✓ | Read-only | ✓ (expanded) |
| Knowledge Notes | ✓ | — | ✓ |
| Playbooks | ✓ | ✓ | ✓ |
| Secrets | ✓ | — | ✓ |
| Attachments | ✓ | — | ✓ |
| Schedules | — | — | ✓ |
| Searches | — | — | ✓ |
| Session Insights | — | ✓ | ✓ |
| Audit Logs | Deprecated | ✓ | ✓ |
| Consumption / ACU | ✓ (basic) | ✓ (detailed) | ✓ (granular) |
| Metrics (DAU/WAU/MAU/PRs) | — | ✓ | ✓ |
| Organizations | — | ✓ | ✓ |
| Users / Members | — | ✓ | ✓ |
| Service Users | — | — | ✓ |
| Roles | — | ✓ | ✓ |
| Git Connections/Permissions | — | — | ✓ |
| Repositories | — | ✓ (basic) | ✓ (indexing) |
| Tags | — | — | ✓ |
| IDP Groups | — | — | ✓ |
| Queue Health | — | — | ✓ |
| Hypervisors | — | ✓ | ✓ |
| IP Access List | — | — | ✓ |
| Guardrail Violations | — | — | ✓ (beta) |
| Snapshots | — | ✓ | — |
| API Key Management | — | ✓ | — (use Service Users) |

## OpenAPI Specifications

Official machine-readable specs:
- **v1**: `https://docs.devin.ai/v1-openapi.yaml`
- **v2**: `https://docs.devin.ai/v2-openapi.yaml`
- **v3**: `https://docs.devin.ai/v3-openapi.yaml`

## Detailed References

- [v1 API Reference](devin-api-v1.md)
- [v2 API Reference](devin-api-v2.md)
- [v3 API Reference](devin-api-v3.md)
- [Migration Guide (v1 → v3)](devin-api-migration-guide.md)
- [App Usage & Recommendations](devin-api-app-usage.md)

## Official Documentation

- [API Overview](https://docs.devin.ai/api-reference/overview)
- [API Release Notes](https://docs.devin.ai/api-reference/release-notes)
- [v3 Usage Examples](https://docs.devin.ai/api-reference/v3/usage-examples)
