# Devin API v3 Reference

**Base URLs**:
- Organization scope: `https://api.devin.ai/v3/organizations/{org_id}/*`
- Enterprise scope: `https://api.devin.ai/v3/enterprise/*`
- Beta: Some endpoints still use `/v3beta1/` prefix

**Status**: **GA — recommended for all new development**
**Auth**: Service User credentials (`cog_*` prefix) with RBAC permissions
**Pagination**: Cursor-based (`first`/`after`/`end_cursor`/`has_next_page`)

---

## Pagination

All list endpoints use cursor-based pagination:

| Parameter | Type | Default | Max | Notes |
|-----------|------|---------|-----|-------|
| `first` | integer | 100 | 200 | Items per page |
| `after` | string | null | — | Cursor from previous response |

**Response wrapper**:
```json
{
  "items": [...],
  "end_cursor": "cursor_xyz",
  "has_next_page": true,
  "total": 500
}
```

---

## Sessions

### Organization-Scoped

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/organizations/{org_id}/sessions` | `ViewOrgSessions` |
| `POST` | `/v3/organizations/{org_id}/sessions` | `UseDevinSessions` |
| `GET` | `/v3/organizations/{org_id}/sessions/{devin_id}` | `ViewOrgSessions` |
| `DELETE` | `/v3/organizations/{org_id}/sessions/{devin_id}` | `ManageOrgSessions` |
| `POST` | `/v3/organizations/{org_id}/sessions/{devin_id}/archive` | `ManageOrgSessions` |
| `POST` | `/v3/organizations/{org_id}/sessions/{devin_id}/messages` | `ManageOrgSessions` |
| `GET` | `/v3/organizations/{org_id}/sessions/{devin_id}/messages` | `ViewOrgSessions` |
| `GET` | `/v3/organizations/{org_id}/sessions/{devin_id}/attachments` | `ViewOrgSessions` |
| `GET` | `/v3/organizations/{org_id}/sessions/{devin_id}/insights` | `ViewOrgSessions` |
| `GET` | `/v3/organizations/{org_id}/sessions/{devin_id}/tags` | `ViewOrgSessions` |
| `POST` | `/v3/organizations/{org_id}/sessions/{devin_id}/tags` | `ManageOrgSessions` |
| `PUT` | `/v3/organizations/{org_id}/sessions/{devin_id}/tags` | `ManageOrgSessions` |

### Enterprise-Scoped

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/enterprise/sessions` | `ViewAccountSessions` |
| `GET` | `/v3/enterprise/sessions/insights` | `ViewAccountSessions` |
| `GET` | `/v3/enterprise/sessions/{devin_id}` | `ViewAccountSessions` |
| `POST` | `/v3/enterprise/sessions/{devin_id}/messages` | `ManageAccountSessions` |
| `GET` | `/v3/enterprise/sessions/{devin_id}/messages` | `ViewAccountSessions` |
| `GET` | `/v3/enterprise/sessions/{devin_id}/attachments` | `ViewAccountSessions` |
| `GET` | `/v3/enterprise/sessions/{devin_id}/insights` | `ViewAccountSessions` |
| `GET` | `/v3/enterprise/sessions/{devin_id}/tags` | `ViewAccountSessions` |
| `POST` | `/v3/enterprise/sessions/{devin_id}/tags` | `ManageAccountSessions` |
| `PUT` | `/v3/enterprise/sessions/{devin_id}/tags` | `ManageAccountSessions` |

### Create Session Request

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `prompt` | string | **Yes** | Task description |
| `title` | string | No | Auto-generated if omitted |
| `tags` | string[] | No | |
| `playbook_id` | string | No | |
| `child_playbook_id` | string | No | |
| `knowledge_ids` | string[] | No | null=all, []=none |
| `repos` | string[] | No | Limit repository access |
| `secret_ids` | string[] | No | null=all, []=none |
| `attachment_urls` | uri[] | No | Pre-uploaded attachment URLs |
| `session_links` | string[] | No | |
| `session_secrets` | object[] | No | Temporary per-session secrets |
| `max_acu_limit` | integer | No | Must be positive |
| `create_as_user_id` | string | No | Requires `ImpersonateOrgSessions` |
| `bypass_approval` | boolean | No | |
| `advanced_mode` | enum | No | `analyze`, `create`, `improve`, `batch`, `manage` |
| `structured_output_schema` | object | No | JSON Schema Draft 7 |

### Session Response (`SessionResponse`)

```json
{
  "session_id": "string",
  "url": "string",
  "status": "new|claimed|running|exit|error|suspended|resuming",
  "status_detail": "working|waiting_for_user|waiting_for_approval|finished|inactivity|user_request|...",
  "tags": ["string"],
  "org_id": "string",
  "created_at": 1705312200,
  "updated_at": 1705312200,
  "acus_consumed": 1.5,
  "pull_requests": [{ "pr_url": "string", "pr_state": "open|closed|merged" }],
  "title": "string|null",
  "user_id": "string|null",
  "service_user_id": "string|null",
  "playbook_id": "string|null",
  "parent_session_id": "string|null",
  "child_session_ids": ["string"],
  "is_advanced": false,
  "is_archived": false,
  "structured_output": {}
}
```

### Session Insights Response

Extends `SessionResponse` with:
```json
{
  "num_user_messages": 5,
  "num_devin_messages": 12,
  "session_size": "xs|s|m|l|xl",
  "analysis": {
    "classification": {
      "category": "string",
      "confidence": 0.95,
      "programming_languages": ["Python", "TypeScript"],
      "tools_and_frameworks": ["React", "FastAPI"]
    },
    "issues": [{ "id": "string", "issue": "string", "impact": "string", "label": "string" }],
    "action_items": [{ "action_item": "string", "type": "string", "issue_id": "string" }],
    "timeline": [{ "title": "string", "description": "string", "color": "string", "issue_id": "string" }],
    "suggested_prompt": {
      "original_prompt": "string",
      "suggested_prompt": "string",
      "feedback_items": ["string"]
    },
    "note_usage": {
      "good_usages": ["string"],
      "bad_usages": ["string"]
    }
  }
}
```

### List Sessions Query Parameters

| Parameter | Type | Notes |
|-----------|------|-------|
| `first` | integer | Default 100, max 200 |
| `after` | string | Pagination cursor |
| `session_ids` | string[] | Filter by specific IDs |
| `created_after` | integer | Unix timestamp |
| `created_before` | integer | Unix timestamp |
| `updated_after` | integer | Unix timestamp |
| `updated_before` | integer | Unix timestamp |
| `tags` | string[] | Filter by tags |
| `playbook_id` | string | Filter by playbook |
| `origins` | enum[] | `webapp`, `slack`, `teams`, `api`, `linear`, `jira`, `scheduled`, `other` |
| `schedule_id` | string | Filter by schedule |
| `user_ids` | string[] | Filter by user |
| `service_user_ids` | string[] | Filter by service user |
| `org_ids` | string[] | Enterprise only |

### Send Message
```
POST /v3/organizations/{org_id}/sessions/{devin_id}/messages
```

| Field | Type | Required |
|-------|------|----------|
| `message` | string | **Yes** |
| `message_as_user_id` | string | No |

---

## Knowledge Notes

### Organization-Scoped

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/organizations/{org_id}/knowledge/notes` | `ViewOrgKnowledge` |
| `POST` | `/v3/organizations/{org_id}/knowledge/notes` | `ManageOrgKnowledge` |
| `PUT` | `/v3/organizations/{org_id}/knowledge/notes/{note_id}` | `ManageOrgKnowledge` |
| `DELETE` | `/v3/organizations/{org_id}/knowledge/notes/{note_id}` | `ManageOrgKnowledge` |

### Enterprise-Scoped

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/enterprise/knowledge/notes` | `ManageAccountKnowledge` |
| `POST` | `/v3/enterprise/knowledge/notes` | `ManageAccountKnowledge` |
| `PUT` | `/v3/enterprise/knowledge/notes/{note_id}` | `ManageAccountKnowledge` |
| `DELETE` | `/v3/enterprise/knowledge/notes/{note_id}` | `ManageAccountKnowledge` |

### Create/Update Request

| Field | Type | Required |
|-------|------|----------|
| `name` | string | **Yes** |
| `body` | string | **Yes** |
| `trigger` | string | **Yes** |

> **Note**: v3 uses `trigger` instead of v1's `trigger_description`.

### Knowledge Note Response

```json
{
  "note_id": "string",
  "folder_id": "string|null",
  "name": "string",
  "body": "string",
  "trigger": "string",
  "is_enabled": true,
  "created_at": 1705312200,
  "updated_at": 1705312200,
  "access_type": "enterprise|org",
  "org_id": "string|null"
}
```

---

## Playbooks

### Organization-Scoped

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/organizations/{org_id}/playbooks` | `ViewOrgPlaybooks` |
| `POST` | `/v3/organizations/{org_id}/playbooks` | `ManageOrgPlaybooks` |
| `GET` | `/v3/organizations/{org_id}/playbooks/{playbook_id}` | `ViewOrgPlaybooks` |
| `PUT` | `/v3/organizations/{org_id}/playbooks/{playbook_id}` | `ManageOrgPlaybooks` |
| `DELETE` | `/v3/organizations/{org_id}/playbooks/{playbook_id}` | `ManageOrgPlaybooks` |

### Enterprise-Scoped

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/enterprise/playbooks` | `ManageAccountPlaybooks` |
| `POST` | `/v3/enterprise/playbooks` | `ManageAccountPlaybooks` |
| `GET` | `/v3/enterprise/playbooks/{playbook_id}` | `ManageAccountPlaybooks` |
| `PUT` | `/v3/enterprise/playbooks/{playbook_id}` | `ManageAccountPlaybooks` |
| `DELETE` | `/v3/enterprise/playbooks/{playbook_id}` | `ManageAccountPlaybooks` |

### Create/Update Request

| Field | Type | Required |
|-------|------|----------|
| `title` | string | **Yes** |
| `body` | string | **Yes** |
| `macro` | string | No |

### Playbook Response

```json
{
  "playbook_id": "string",
  "title": "string",
  "body": "string",
  "macro": "string|null",
  "created_by": "string",
  "updated_by": "string",
  "created_at": 1705312200,
  "updated_at": 1705312200,
  "access_type": "enterprise|org",
  "org_id": "string|null"
}
```

---

## Secrets

Organization-scoped only.

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/organizations/{org_id}/secrets` | `ManageOrgSecrets` |
| `POST` | `/v3/organizations/{org_id}/secrets` | `ManageOrgSecrets` |
| `DELETE` | `/v3/organizations/{org_id}/secrets/{secret_id}` | `ManageOrgSecrets` |

### Create Request

| Field | Type | Required |
|-------|------|----------|
| `type` | enum | **Yes** | `cookie`, `key-value`, `totp` |
| `key` | string | **Yes** |
| `value` | string | **Yes** |
| `note` | string | No |
| `is_sensitive` | boolean | No (default: true) |

### Secret Response

```json
{
  "secret_id": "string",
  "key": "string|null",
  "note": "string|null",
  "is_sensitive": true,
  "created_by": "string",
  "created_at": 1705312200,
  "secret_type": "cookie|key-value|totp",
  "access_type": "org|personal"
}
```

---

## Attachments

Organization-scoped.

| Method | Path | Permission |
|--------|------|------------|
| `POST` | `/v3/organizations/{org_id}/attachments` | `UseDevinSessions` |
| `GET` | `/v3/organizations/{org_id}/attachments/{uuid}/{name}` | `ViewOrgSessions` |

Upload uses `multipart/form-data`. Download returns `307` redirect.

---

## Schedules

Organization-scoped. Added February 2026.

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/organizations/{org_id}/schedules` | `ViewOrgSchedules` |
| `POST` | `/v3/organizations/{org_id}/schedules` | `ManageOrgSchedules` |
| `GET` | `/v3/organizations/{org_id}/schedules/{schedule_id}` | `ViewOrgSchedules` |
| `PATCH` | `/v3/organizations/{org_id}/schedules/{schedule_id}` | `ManageOrgSchedules` |
| `DELETE` | `/v3/organizations/{org_id}/schedules/{schedule_id}` | `ManageOrgSchedules` |

### Create Request

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `name` | string | **Yes** | |
| `prompt` | string | **Yes** | |
| `frequency` | string | No | Cron-like expression |
| `schedule_type` | enum | No | `recurring` (default), `one_time` |
| `scheduled_at` | datetime | No | For one-time schedules |
| `agent` | enum | No | `devin` (default), `data_analyst`, `advanced` |
| `notify_on` | enum | No | `always`, `failure` (default), `never` |
| `playbook_id` | string | No | |
| `slack_channel_id` | string | No | |
| `slack_team_id` | string | No | |
| `create_as_user_id` | string | No | |

---

## Searches

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/enterprise/searches` | `ViewAccountSessions` |
| `GET` | `/v3/organizations/{org_id}/searches` | `ViewOrgSessions` |

---

## Audit Logs

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/enterprise/audit-logs` | `ManageEnterpriseSettings` |
| `GET` | `/v3/organizations/{org_id}/audit-logs` | `ManageEnterpriseSettings` |

Query: `order` (asc/desc), `time_before`, `time_after`, `after`, `first`, `action` (enum).

---

## Consumption & ACU Limits

### ACU Limits

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/enterprise/consumption/acu-limits/devin` | `ManageBilling` |
| `PUT` | `/v3/enterprise/consumption/acu-limits/devin/organizations/{org_id}` | `ManageBilling` |
| `DELETE` | `/v3/enterprise/consumption/acu-limits/devin/organizations/{org_id}` | `ManageBilling` |

### Consumption Data

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/enterprise/consumption/cycles` | `ManageBilling` |
| `GET` | `/v3/enterprise/consumption/daily` | `ManageBilling` |
| `GET` | `/v3/enterprise/consumption/daily/organizations/{org_id}` | `ManageBilling` |
| `GET` | `/v3/enterprise/consumption/daily/users/{user_id}` | `ManageBilling` |
| `GET` | `/v3/enterprise/consumption/daily/sessions/{session_id}` | `ManageBilling` |
| `GET` | `/v3/enterprise/consumption/daily/service-users/{id}` | `ManageBilling` |

### Consumption Response

```json
{
  "total_acus": 150.5,
  "consumption_by_date": [
    {
      "date": 1705276800,
      "acus": 10.5,
      "acus_by_product": {
        "devin": 8.0,
        "cascade": 1.5,
        "terminal": 1.0
      }
    }
  ]
}
```

> **Note**: v3 consumption breaks down ACUs by product (devin, cascade, terminal). v1 only provides a total.

---

## Metrics

Enterprise-scoped.

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/enterprise/metrics/active-users` | `ViewAccountAnalytics` |
| `GET` | `/v3/enterprise/metrics/dau` | `ViewAccountAnalytics` |
| `GET` | `/v3/enterprise/metrics/wau` | `ViewAccountAnalytics` |
| `GET` | `/v3/enterprise/metrics/mau` | `ViewAccountAnalytics` |
| `GET` | `/v3/enterprise/metrics/prs` | `ViewAccountAnalytics` |
| `GET` | `/v3/enterprise/metrics/searches` | `ViewAccountAnalytics` |
| `GET` | `/v3/enterprise/metrics/sessions` | `ViewAccountAnalytics` |
| `GET` | `/v3/enterprise/metrics/usage` | `ViewAccountAnalytics` |
| `GET` | `/v3/organizations/{org_id}/metrics/usage` | `ViewOrgAnalytics` |

---

## Queue Health

```
GET /v3/enterprise/queue
```
Permission: `ViewAccountSessions`

Returns total queued sessions and a status indicator.

---

## Organizations

Enterprise-scoped.

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/enterprise/organizations` | `ViewAccountOrganizations` |
| `POST` | `/v3/enterprise/organizations` | `ManageAccountOrganizations` |
| `GET` | `/v3/enterprise/organizations/{org_id}` | `ViewAccountOrganizations` |
| `PATCH` | `/v3/enterprise/organizations/{org_id}` | `ManageAccountOrganizations` |
| `DELETE` | `/v3/enterprise/organizations/{org_id}` | `ManageAccountOrganizations` |

---

## Users

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/enterprise/members/users` | `ViewAccountMembers` |
| `POST` | `/v3/enterprise/members/users` | `ManageAccountMembers` |
| `GET` | `/v3/enterprise/members/users/{user_id}` | `ViewAccountMembers` |
| `PATCH` | `/v3/enterprise/members/users/{user_id}` | `ManageAccountMembers` |
| `DELETE` | `/v3/enterprise/members/users/{user_id}` | `ManageAccountMembers` |
| `GET` | `/v3/organizations/{org_id}/members/users` | `ViewOrgMembers` |
| `POST` | `/v3/organizations/{org_id}/members/users` | `ManageOrgMembers` |
| `PATCH` | `/v3/organizations/{org_id}/members/users/{user_id}` | `ManageOrgMembers` |
| `DELETE` | `/v3/organizations/{org_id}/members/users/{user_id}` | `ManageOrgMembers` |

---

## Service Users

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/enterprise/members/service-users` | `ViewAccountMembers` |
| `POST` | `/v3/enterprise/members/service-users` | `ManageAccountServiceUsers` |
| `GET` | `/v3/enterprise/members/service-users/{id}` | `ViewAccountMembers` |
| `PATCH` | `/v3/enterprise/members/service-users/{id}` | `ManageAccountServiceUsers` |
| `DELETE` | `/v3/enterprise/members/service-users/{id}` | `ManageAccountServiceUsers` |
| `POST` | `/v3beta1/enterprise/service-users` | `ManageAccountServiceUsers` |
| `POST` | `/v3beta1/organizations/{org_id}/service-users` | `ManageOrgServiceUsers` |
| `GET` | `/v3/organizations/{org_id}/members/service-users` | `ViewOrgMembers` |
| `POST` | `/v3/organizations/{org_id}/members/service-users` | `ManageOrgServiceUsers` |
| `PATCH` | `/v3/organizations/{org_id}/members/service-users/{id}` | `ManageOrgServiceUsers` |
| `DELETE` | `/v3/organizations/{org_id}/members/service-users/{id}` | `ManageOrgServiceUsers` |

> **Note**: Provisioning endpoints (which return the API token) are still on `/v3beta1/`. The token is shown **only once** at creation.

---

## Roles

```
GET /v3/enterprise/roles
```
Permission: `ViewAccountRoles`

Returns: `{ role_id, role_name, role_type }`

---

## Tags

Organization-scoped.

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/organizations/{org_id}/tags` | `ViewOrgTags` |
| `POST` | `/v3/organizations/{org_id}/tags` | `ManageOrgTags` |
| `PUT` | `/v3/organizations/{org_id}/tags` | `ManageOrgTags` |
| `DELETE` | `/v3/organizations/{org_id}/tags` | `ManageOrgTags` |
| `DELETE` | `/v3/organizations/{org_id}/tags/{tag}` | `ManageOrgTags` |
| `GET` | `/v3/enterprise/organizations/{org_id}/default-tag` | `ManageAccountOrganizations` |
| `PUT` | `/v3/enterprise/organizations/{org_id}/default-tag` | `ManageAccountOrganizations` |
| `DELETE` | `/v3/enterprise/organizations/{org_id}/default-tag` | `ManageAccountOrganizations` |

---

## Git Connections & Permissions

### Git Connections

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/enterprise/git-providers/connections` | `ViewAccountGitPermissions` |

### Git Permissions

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/organizations/{org_id}/git-providers/permissions` | `ViewOrgGitPermissions` |
| `POST` | `/v3/organizations/{org_id}/git-providers/permissions` | `ManageOrgGitPermissions` |
| `PUT` | `/v3/organizations/{org_id}/git-providers/permissions` | `ManageOrgGitPermissions` |
| `DELETE` | `/v3/organizations/{org_id}/git-providers/permissions` | `ManageOrgGitPermissions` |
| `DELETE` | `/v3/organizations/{org_id}/git-providers/permissions/{id}` | `ManageOrgGitPermissions` |

Supports prefix path matching for repository access control.

---

## Repositories

Organization-scoped.

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/organizations/{org_id}/repositories` | `ViewOrgRepositories` |
| `GET` | `/v3/organizations/{org_id}/repositories/indexed` | `ViewOrgRepositories` |
| `POST` | `/v3/organizations/{org_id}/repositories/index` | `ManageOrgRepositories` |
| `POST` | `/v3/organizations/{org_id}/repositories/bulk-index` | `ManageOrgRepositories` |
| `DELETE` | `/v3/organizations/{org_id}/repositories/{repo_id}` | `ManageOrgRepositories` |
| `DELETE` | `/v3/organizations/{org_id}/repositories/{repo_id}/branches/{branch}` | `ManageOrgRepositories` |
| `DELETE` | `/v3/organizations/{org_id}/repositories/bulk-remove` | `ManageOrgRepositories` |
| `GET` | `/v3/organizations/{org_id}/repositories/{repo_id}/status` | `ViewOrgRepositories` |

---

## IDP Groups

Enterprise-scoped.

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/enterprise/idp-groups` | `ManageEnterpriseSettings` |
| `POST` | `/v3/enterprise/idp-groups` | `ManageEnterpriseSettings` |
| `DELETE` | `/v3/enterprise/idp-groups/{idp_group_name}` | `ManageEnterpriseSettings` |

Bulk creation supports up to 100 groups per request.

---

## Infrastructure

### Hypervisors
```
GET /v3/enterprise/hypervisors
```
Default filter: `available` status. Returns `utilization_percentage`.

### IP Access List

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/enterprise/ip-access-list` | `ManageEnterpriseSettings` |
| `PUT` | `/v3/enterprise/ip-access-list` | `ManageEnterpriseSettings` |
| `DELETE` | `/v3/enterprise/ip-access-list` | `ManageEnterpriseSettings` |

### Org Group Limits

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3/enterprise/org-group-limits` | `ManageAccountOrganizations` |
| `PUT` | `/v3/enterprise/org-group-limits` | `ManageAccountOrganizations` |

---

## Guardrail Violations (Beta)

| Method | Path | Permission |
|--------|------|------------|
| `GET` | `/v3beta1/enterprise/guardrail-violations` | `ViewAccountSessions` |
| `GET` | `/v3beta1/enterprise/organizations/{org_id}/guardrail-violations` | `ViewAccountSessions` |

---

## Self

```
GET /v3/enterprise/self
```
Permission: any valid service user credential.

**Response**:
```json
{
  "service_user_id": "string",
  "service_user_name": "string",
  "org_id": "string|null"
}
```

---

## v3 Status Enums

### `status` (top-level session state)
| Value | Meaning |
|-------|---------|
| `new` | Just created |
| `claimed` | Assigned to a worker |
| `running` | Actively executing |
| `exit` | Completed normally |
| `error` | Failed with error |
| `suspended` | Paused |
| `resuming` | Being resumed |

### `status_detail` (contextual detail)

When `status` is `running`:
| Value | Meaning |
|-------|---------|
| `working` | Actively working on task |
| `waiting_for_user` | Needs user input |
| `waiting_for_approval` | Needs approval |
| `finished` | Task complete, wrapping up |

When `status` is `suspended`:
| Value | Meaning |
|-------|---------|
| `inactivity` | Auto-suspended for inactivity |
| `user_request` | User-initiated suspend |
| `usage_limit_exceeded` | Hit session ACU limit |
| `out_of_credits` | Account has no credits |
| `payment_declined` | Payment issue |
| `org_usage_limit_exceeded` | Org-level limit hit |
| `error` | Suspended due to error |

---

## RBAC Permissions Reference

Key permissions used across v3 endpoints:

| Permission | Grants Access To |
|------------|-----------------|
| `ViewOrgSessions` | Read sessions, messages, attachments, insights, tags |
| `UseDevinSessions` | Create sessions, upload attachments |
| `ManageOrgSessions` | Send messages, archive, terminate, manage tags |
| `ImpersonateOrgSessions` | Use `create_as_user_id` |
| `ViewOrgKnowledge` | Read knowledge notes |
| `ManageOrgKnowledge` | Create/update/delete knowledge notes |
| `ViewOrgPlaybooks` | Read playbooks |
| `ManageOrgPlaybooks` | Create/update/delete playbooks |
| `ManageOrgSecrets` | Full secrets access |
| `ManageBilling` | Consumption data, ACU limits |
| `ViewAccountSessions` | Enterprise-wide session read |
| `ManageAccountSessions` | Enterprise-wide session management |
| `ManageAccountKnowledge` | Enterprise knowledge management |
| `ManageAccountPlaybooks` | Enterprise playbook management |
| `ViewAccountAnalytics` | Metrics and usage data |
| `ManageEnterpriseSettings` | Audit logs, IP lists, IDP groups |
| `ManageAccountServiceUsers` | Service user provisioning |
| `ViewAccountMembers` | Read enterprise members |
| `ManageAccountMembers` | Manage enterprise members |
| `ViewAccountOrganizations` | Read organizations |
| `ManageAccountOrganizations` | Manage organizations, org group limits |
| `ViewAccountRoles` | Read roles |
