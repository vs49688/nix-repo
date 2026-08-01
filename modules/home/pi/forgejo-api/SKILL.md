---
name: forgejo-api
description: Interact with Forgejo/Gitea REST APIs — issues, milestones, repos, PRs. Use when the user mentions Forgejo, Gitea, self-hosted git, or git.vs49688.net.
---

## Forgejo API

Base URL: `{instance}/api/v1/`
Full API spec: `{instance}/swagger.v1.json` (OpenAPI 2.0)

### Auth

Tokens live in `.gitea_token` at the repo root.

Two-step workflow:
1. Read the token: `read .gitea_token`
2. Use `web_request` with `headers={"Authorization":"token {token}"}`

```
web_request: method="GET", url="https://git.vs49688.net/api/v1/repos/owner/repo/issues",
             headers={"Authorization":"token AAAAAAAA..."}
```

### Common Endpoints

**Milestones:**
- List: `GET /repos/{owner}/{repo}/milestones`
- Create: `POST /repos/{owner}/{repo}/milestones` — body: `{"title":"...", "description":"..."}`

**Issues:**
- List: `GET /repos/{owner}/{repo}/issues?milestone={id}&state=open`
- Create: `POST /repos/{owner}/{repo}/issues` — body: `{"title":"...", "body":"...", "milestone":{id}}`

**Labels:**
- List: `GET /repos/{owner}/{repo}/labels`

**Repos:**
- List: `GET /repos/search?q=...&topic=true`
- Get: `GET /repos/{owner}/{repo}`

### Key Gotchas

- Label assignment in issue creation uses label IDs (integers), not names
- 409 on issue creation means a duplicate
- Milestone `due_on` uses ISO 8601 with timezone: `2026-06-30T00:00:00+10:00`
- The `labels` field on CreateIssueOption accepts `[]int64`, not `[]string`

### Unknown Endpoints

Fetch the Swagger spec:

```
web_request: method="GET", url="https://git.vs49688.net/swagger.v1.json",
             headers={"Authorization":"token {token}"}
```

Then grep the response for the endpoint path.
