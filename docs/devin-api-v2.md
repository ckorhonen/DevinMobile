# Devin API v2 Reference

**Base URL**: `https://api.devin.ai/v2/enterprise`
**Status**: Legacy — no new features, deprecation planned
**Auth**: Bearer token with Enterprise Admin personal API keys only (`apk_user_*` with admin role)
**Pagination**: Offset-based (max 200 items per page)
**Scope**: Enterprise-wide (cross-organization)

> **Note**: Service API keys and org-level keys are **not** accepted on v2 endpoints. Only personal keys belonging to users with the Enterprise Admin role will work.

---

## Self

### Get Authenticated Identity
```
GET /v2/enterprise/self
```

**Response**:
```json
{
  "api_key_id": "string",
  "user_id": "string",
  "user_email": "string",
  "org_id": "string"
}
```

---

## API Key Management

### Provision Service Key
```
POST /v2/enterprise/api-keys/provision-service-key
```

### List Enterprise API Keys
```
GET /v2/enterprise/api-keys/list-enterprise-api-keys
```

### Revoke API Key
```
POST /v2/enterprise/api-keys/revoke-enterprise-api-key
```

### Revoke All API Keys
```
POST /v2/enterprise/api-keys/revoke-all-enterprise-api-keys
```

---

## Audit Logs

### Get Audit Logs
```
GET /v2/enterprise/audit-logs
```

---

## Consumption & Metrics

### Consumption Cycles
```
GET /v2/enterprise/consumption/consumption-cycles
```

### Daily Consumption
```
GET /v2/enterprise/consumption/daily-consumption
```

### User Daily Consumption
```
GET /v2/enterprise/consumption/user-daily-consumption
```

### PR Metrics
```
GET /v2/enterprise/consumption/pr-metrics
```

### Session Metrics
```
GET /v2/enterprise/consumption/sessions-metrics
```

### Search Metrics
```
GET /v2/enterprise/consumption/searches-metrics
```

### Usage Metrics
```
GET /v2/enterprise/consumption/usage-metrics
```

---

## Groups

### List Enterprise Groups
```
GET /v2/enterprise/groups/list-enterprise-groups
```

### Add Enterprise Groups
```
POST /v2/enterprise/groups/add-enterprise-groups
```

### Get Group Details
```
GET /v2/enterprise/groups/get-group-details
```

---

## Members

### List Enterprise Members
```
GET /v2/enterprise/members/list-enterprise-members
```

### Get Member Details
```
GET /v2/enterprise/members/get-member-details
```

### Invite Enterprise Members
```
POST /v2/enterprise/members/invite-enterprise-members
```

### Update Member Roles
```
PUT /v2/enterprise/members/update-member-roles
```

### Delete Enterprise Member
```
DELETE /v2/enterprise/members/delete-enterprise-member
```

### List Roles
```
GET /v2/enterprise/members/list-roles
```

---

## Organizations

### List Organizations
```
GET /v2/enterprise/organizations/list-organizations
```

### Create Organization
```
POST /v2/enterprise/organizations/create-organization
```

### Get Organization Details
```
GET /v2/enterprise/organizations/get-organization-details
```

### Update Organization
```
PUT /v2/enterprise/organizations/update-organization
```

### Delete Organization
```
DELETE /v2/enterprise/organizations/delete-organization
```

### List Organization Members
```
GET /v2/enterprise/organizations/{org_id}/members
```

### Clone Repository
```
POST /v2/enterprise/organizations/{org_id}/clone-repository
```

---

## Sessions (Read-Only)

v2 provides read-only enterprise-wide access to sessions. For creating or managing sessions, use v1 or v3.

### List Enterprise Sessions
```
GET /v2/enterprise/sessions/list-enterprise-sessions
```

### List Session Insights
```
GET /v2/enterprise/sessions/list-enterprise-sessions-insights
```

### Get Enterprise Session
```
GET /v2/enterprise/sessions/get-enterprise-session
```

### List Organization Sessions
```
GET /v2/enterprise/organizations/{org_id}/sessions
```

### List Organization Session Insights
```
GET /v2/enterprise/organizations/{org_id}/sessions/insights
```

---

## Playbooks

### List Playbooks
```
GET /v2/enterprise/playbooks/list-playbooks
```

### Create Playbook
```
POST /v2/enterprise/playbooks/create-playbook
```

### Get Playbook
```
GET /v2/enterprise/playbooks/get-playbook
```

### Update Playbook
```
PUT /v2/enterprise/playbooks/update-playbook
```

### Delete Playbook
```
DELETE /v2/enterprise/playbooks/delete-playbook
```

---

## Infrastructure

### List Hypervisors
```
GET /v2/enterprise/hypervisors
```

### Get Org Group Limits
```
GET /v2/enterprise/org-group-limits
```

### Update Org Group Limits
```
PUT /v2/enterprise/org-group-limits
```

---

## Snapshots

### Get Snapshot
```
GET /v2/enterprise/snapshots/{snapshot_id}
```

### Create Snapshot
```
POST /v2/enterprise/snapshots
```

---

## Repositories (Beta)

### Bulk Index Repositories
```
POST /v2/enterprise/repositories/bulk-index
```

### Get Repository Indexing Status
```
GET /v2/enterprise/repositories/{repo_id}/status
```

---

## Roles

### List Roles
```
GET /v2/enterprise/roles
```

### Create Role
```
POST /v2/enterprise/roles
```

### Get Role
```
GET /v2/enterprise/roles/{role_id}
```

### Update Role
```
PUT /v2/enterprise/roles/{role_id}
```

### Delete Role
```
DELETE /v2/enterprise/roles/{role_id}
```

---

## User Usage (Beta)

```
GET /v2/enterprise/user-usage
```

---

## Relevance to DevinMobile

The v2 API is **enterprise admin only** and primarily useful for:
- Organization management dashboards
- Usage analytics and consumption tracking
- Member and role management
- Audit compliance

For the mobile app's core functionality (sessions, knowledge, playbooks, secrets), v2 adds no value over v1. The metrics and consumption endpoints in v2 are superseded by more granular v3 equivalents. **Recommendation: Skip v2 entirely and migrate from v1 directly to v3.**
