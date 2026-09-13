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

### Keeping Responses Small

`web_request` returns the whole body, and Forgejo's objects are fat: one
issue is ~1 KB (25 fields, including a nested `repository` blob), a
50-issue list is ~145 KB, and the full swagger spec is ~850 KB. Pass
`filter` — a JavaScript expression with the parsed JSON body bound as
`data` — to keep only what you need:

    web_request: method="GET", url="...", headers={...},
                 filter="data.map(i => ({number: i.number, title: i.title, state: i.state}))"

Common shapes:

| Want | filter |
|------|--------|
| One issue/PR | `({number: data.number, title: data.title, state: data.state, html_url: data.html_url})` |
| A list of issues | `data.map(({number,title,state}) => ({number,title,state}))` |
| Search results | `data.data.map(r => ({name: r.full_name, private: r.private}))` |
| Keys of an object | `Object.keys(data.paths)` |

`filter` requires a JSON body; if the expression throws, the tool reports
the error plus a short preview rather than failing silently. `maxBytes`
caps the returned body when you don't filter (useful for HTML). Milestone
objects are already small (~200 B) — no need to project those.

### Common Endpoints

**Milestones:**
- List: `GET /repos/{owner}/{repo}/milestones`
- Create: `POST /repos/{owner}/{repo}/milestones` — body: `{"title":"...", "description":"..."}` (responses are ~200 B)

**Issues:**
- List: `GET /repos/{owner}/{repo}/issues?milestone={id}&state=open` — always project (see above)
- Create: `POST /repos/{owner}/{repo}/issues` — body: `{"title":"...", "body":"...", "milestone":{id}}`
- Update: `PATCH /repos/{owner}/{repo}/issues/{index}` — returns the full issue, so project it, e.g. `filter="({number: data.number, html_url: data.html_url})"`
- Comment: `POST /repos/{owner}/{repo}/issues/{index}/comments` — body: `{"body":"..."}`; project to `({id: data.id, html_url: data.html_url})`

**Labels:**
- List: `GET /repos/{owner}/{repo}/labels`

**Repos:**
- List: `GET /repos/search?q=...&topic=true` — the response is an envelope (`{data:[...]}`); project to `data.data.map(r => ({name: r.full_name, private: r.private}))`
- Get: `GET /repos/{owner}/{repo}`

### Key Gotchas

- Label assignment in issue creation uses label IDs (integers), not names
- 409 on issue creation means a duplicate
- Milestone `due_on` uses ISO 8601 with timezone: `2026-06-30T00:00:00+10:00`
- The `labels` field on CreateIssueOption accepts `[]int64`, not `[]string`

### Unknown Endpoints

The swagger spec is ~850 KB — never pull it into context raw. It needs no
auth, so fetch it to a file and grep locally:

    curl -s https://git.vs49688.net/swagger.v1.json -o /tmp/swagger.json
    jq -r '.paths | keys[]' /tmp/swagger.json | grep -i issues

Or keep it in `web_request` with a projection:
`filter="Object.keys(data.paths).filter(p => p.includes('issues'))"`.
