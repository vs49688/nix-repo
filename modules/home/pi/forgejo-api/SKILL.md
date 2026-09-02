---
name: forgejo-api
description: Interact with Forgejo/Gitea REST APIs — issues, milestones, repos, PRs. Use when the user mentions Forgejo, Gitea, self-hosted git, or git.vs49688.net.
---

## Forgejo API

Base URL: `{instance}/api/v1/`
Full API spec: `{instance}/swagger.v1.json` (OpenAPI 2.0)

### Auth

The API token lives at `~/.config/sops-nix/secrets/agents/forgejo_token`.

Pass it to `web_request` as a file reference:

```
web_request: method="GET", url="https://git.vs49688.net/api/v1/repos/{owner}/{repo}/issues",
             headers={"Authorization":{"file":"~/.config/sops-nix/secrets/agents/forgejo_token","prefix":"token "}}
```

`web_request` reads the file itself: leading/trailing whitespace is trimmed
(token files end with a newline) and `~` expands to the home directory.
`prefix` and optional `suffix` wrap the contents, so `"prefix":"token "`
yields `Authorization: token <token>`.

`web_request` never runs shell expansions: `$(cat ...)` or `$VAR` inside a
header value is sent literally, so always use the file-object form above,
never shell substitution.

The token belongs to the agent's own account, but repos may be owned by
other users: always use the real owner in the URL path
(`repos/{owner}/{repo}/...`), never assume it is the token's account.

Sanity-check the token:

```
web_request: method="GET", url="https://git.vs49688.net/api/v1/user",
             headers={"Authorization":{"file":"~/.config/sops-nix/secrets/agents/forgejo_token","prefix":"token "}}
```

`200` with `{"login":"<your account>",...}` means the token works; `401`
means it does not.

### Troubleshooting

Forgejo's status codes are easy to misread:

| Status | Meaning |
|--------|---------|
| 401 | Token problem: missing, malformed, expired, or a file-form mistake. |
| 404 | Wrong `{owner}/{repo}` path, repo doesn't exist, or exists but is private to another account — Forgejo hides private repos, so this happens with valid tokens too. |

If `/api/v1/user` returns 200, the token is fine and any 404 is a path or
visibility problem, not an auth failure.

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
             headers={"Authorization":{"file":"~/.config/sops-nix/secrets/agents/forgejo_token","prefix":"token "}}
```

Then grep the response for the endpoint path.
