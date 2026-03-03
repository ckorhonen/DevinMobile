# Devin API v1 Reference

**Base URL**: `https://api.devin.ai/v1`
**Status**: Legacy — no new features, deprecation planned
**Auth**: Bearer token with Personal (`apk_user_*`) or Service (`apk_*`) API keys
**Pagination**: Offset-based (`limit`/`offset`)

---

## Sessions

### List Sessions
```
GET /v1/sessions
```

| Parameter | Type | Default | Notes |
|-----------|------|---------|-------|
| `limit` | integer | 100 | Max items per page |
| `offset` | integer | 0 | Skip N items |
| `skip` | integer | null | Alternative to offset |
| `tags` | string[] | null | Filter by tags |
| `user_email` | string | null | Filter by user |

**Response** (`SessionListResponse`):
```json
{
  "sessions": [
    {
      "session_id": "string",
      "status": "string",
      "status_enum": "working|blocked|expired|finished|...",
      "title": "string|null",
      "created_at": "2025-01-15T10:30:00Z",
      "updated_at": "2025-01-15T10:30:00Z",
      "acus_consumed": 1.5,
      "url": "https://app.devin.ai/sessions/...",
      "pull_request": { "url": "string", "title": "string", "number": 42 },
      "structured_output": {},
      "playbook_id": "string|null",
      "tags": ["string"]
    }
  ]
}
```

### Create Session
```
POST /v1/sessions
```

**Request Body** (`CreateSessionRequest`):

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `prompt` | string | **Yes** | Task description for Devin |
| `idempotent` | boolean | No | Default: false |
| `unlisted` | boolean | No | Default: false |
| `title` | string | No | Auto-generated if omitted |
| `playbook_id` | string | No | Apply a playbook |
| `snapshot_id` | string | No | Resume from snapshot |
| `max_acu_limit` | integer | No | Must be positive |
| `tags` | string[] | No | Max 50 items |
| `knowledge_ids` | string[] | No | null=all, []=none |
| `secret_ids` | string[] | No | null=all, []=none |
| `session_secrets` | object[] | No | Temporary per-session secrets |
| `structured_output_schema` | object | No | JSON Schema Draft 7, max 64KB |

**`session_secrets` item**:
```json
{ "key": "string (1-256 chars)", "value": "string (max 65536)", "sensitive": true }
```

**Response** (`CreateSessionResponse`):
```json
{
  "session_id": "string",
  "url": "https://app.devin.ai/sessions/...",
  "is_new_session": true
}
```

### Get Session
```
GET /v1/sessions/{session_id}
```

**Response** (`SessionDetailResponse`):
```json
{
  "session_id": "string",
  "status": "string",
  "status_enum": "working",
  "title": "string|null",
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-15T10:30:00Z",
  "url": "https://app.devin.ai/sessions/...",
  "pull_request": { "url": "string", "title": "string", "number": 42 },
  "acus_consumed": 1.5,
  "messages": [
    {
      "event_id": "string",
      "type": "string",
      "message": "string",
      "timestamp": "2025-01-15T10:30:00Z",
      "origin": "user|devin|api|slack|frontend",
      "user_id": "string|null",
      "username": "string|null"
    }
  ],
  "structured_output": {},
  "playbook_id": "string|null",
  "tags": ["string"]
}
```

> **Note**: v1 returns messages inline in the session detail response. In v3, messages are a separate sub-resource.

### Delete/Terminate Session
```
DELETE /v1/sessions/{session_id}
```

Returns `204 No Content` on success.

### Send Message
```
POST /v1/sessions/{session_id}/message
```

> **Note**: v1 uses singular `/message`. v3 uses plural `/messages`.

**Request Body**:
```json
{ "message": "your follow-up instruction" }
```

### Update Session Tags
```
PUT /v1/sessions/{session_id}/tags
```

**Request Body**:
```json
{ "tags": ["tag1", "tag2"] }
```
Max 50 tags.

### List Session Attachments
```
GET /v1/sessions/{session_id}/attachments
```

**Response**:
```json
[
  {
    "attachment_id": "string",
    "name": "filename.txt",
    "url": "string",
    "source": "string",
    "content_type": "text/plain"
  }
]
```

---

## Knowledge

### List Knowledge
```
GET /v1/knowledge
```

**Response** (`KnowledgeListResponse`):
```json
{
  "knowledge": [
    {
      "id": "string",
      "name": "string",
      "body": "string",
      "trigger_description": "string",
      "created_at": "2025-01-15T10:30:00Z",
      "macro": "string|null",
      "parent_folder_id": "string|null",
      "pinned_repo": "string|null",
      "created_by": { "user_id": "string", "user_name": "string" }
    }
  ],
  "folders": [
    {
      "folder_id": "string",
      "name": "string",
      "parent_folder_id": "string|null"
    }
  ]
}
```

### Create Knowledge Note
```
POST /v1/knowledge
```

**Request Body** (`CreateNoteRequest`):

| Field | Type | Required |
|-------|------|----------|
| `name` | string | **Yes** |
| `body` | string | **Yes** |
| `trigger_description` | string | **Yes** |
| `macro` | string | No |
| `parent_folder_id` | string | No |
| `pinned_repo` | string | No |

### Update Knowledge Note
```
PUT /v1/knowledge/{note_id}
```

Same body as create — all fields optional for partial updates.

### Delete Knowledge Note
```
DELETE /v1/knowledge/{note_id}
```

Returns `204 No Content`.

---

## Playbooks

### List Playbooks
```
GET /v1/playbooks
```

**Response**:
```json
[
  {
    "playbook_id": "string",
    "title": "string",
    "body": "string",
    "status": "string",
    "access_type": "org|personal",
    "org_id": "string",
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-01-15T10:30:00Z",
    "created_by_user_id": "string",
    "created_by_user_name": "string",
    "updated_by_user_id": "string",
    "updated_by_user_name": "string",
    "macro": "string|null"
  }
]
```

### Create Playbook
```
POST /v1/playbooks
```

| Field | Type | Required |
|-------|------|----------|
| `title` | string | **Yes** (minLength 1) |
| `body` | string | **Yes** (minLength 1) |
| `macro` | string | No |

### Get Playbook
```
GET /v1/playbooks/{playbook_id}
```

### Update Playbook
```
PUT /v1/playbooks/{playbook_id}
```

Same body as create.

### Delete Playbook
```
DELETE /v1/playbooks/{playbook_id}
```

---

## Secrets

### List Secrets
```
GET /v1/secrets
```

Returns metadata only — secret values are never returned.

**Response**:
```json
[
  {
    "id": "string",
    "type": "cookie|key-value|dictionary|totp",
    "key": "string|null",
    "created_at": "2025-01-15T10:30:00Z"
  }
]
```

### Create Secret
```
POST /v1/secrets
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `type` | enum | **Yes** | `cookie`, `key-value`, `totp` (`dictionary` deprecated) |
| `key` | string | **Yes** | Unique name |
| `value` | string | **Yes** | Encrypted at rest |
| `sensitive` | boolean | **Yes** | |
| `note` | string | **Yes** | Description |
| `scope` | enum | No | `org` (default) or `personal` |

### Delete Secret
```
DELETE /v1/secrets/{secret_id}
```

---

## Attachments

### Upload Attachment
```
POST /v1/attachments
Content-Type: multipart/form-data
```

Form field: `file`

**Response**: URL string. Reference in session prompts as `ATTACHMENT:"<url>"`.

### Download Attachment
```
GET /v1/attachments/{uuid}/{name}
```

Returns `307` redirect to a presigned download URL.

---

## Enterprise Consumption

### Get Consumption
```
GET /v1/enterprise/consumption
```

| Parameter | Type | Notes |
|-----------|------|-------|
| `start_date` | string | Optional |
| `end_date` | string | Optional |
| `date_start` | string | Alternative param name |
| `date_end` | string | Alternative param name |

**Response**:
```json
{
  "total_acus": 150.5,
  "consumption_by_date": [
    { "date": "2025-01-15", "acus": 10.5 }
  ]
}
```

---

## `status_enum` Values

| Value | Meaning |
|-------|---------|
| `working` | Devin is actively working |
| `blocked` | Waiting for user input |
| `expired` | Session timed out |
| `finished` | Task completed |
| `suspend_requested` | System-initiated suspend |
| `suspend_requested_frontend` | User-initiated suspend |
| `resume_requested` | System-initiated resume |
| `resume_requested_frontend` | User-initiated resume |
| `resumed` | Session has resumed |
