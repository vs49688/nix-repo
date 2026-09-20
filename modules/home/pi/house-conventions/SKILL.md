---
name: house-conventions
description: Conventions for Zane's own projects — Go style and tooling, the `framework` persistence layer, and the engineering method used across them. Use when working in one of Zane's repositories, especially on Go code, a persistence layer, a schema, or a migration.
---

# House conventions

These are the conventions for Zane's own projects. `framework` (module
`git.vs49688.net/zane/framework`) is the shared Go library they build on, and is
intended to become public.

The framework's persistence layer was **extracted from the oldest of these
projects, and the rest inherit it**. That is why the rules below are
framework-level policy rather than one repo's taste: where a repo differs from
them, it is drift to reconcile, not a variant to preserve.

Two scoping notes:

- **Per-repo deltas do not belong here.** Domain rules, ports, service names,
  build quirks and project history live in each repo's own `AGENTS.md`.
- **This document carries policy, usage patterns and naming. It deliberately
  does not restate API contracts** — for those, read the package doc comments.
  Paraphrasing an API is how the previous copies of these conventions drifted
  away from the code.
- **This elaborates the global agent guide for Go and the framework; it does not
  restate it.** The guide is loaded into every session and this is not, so a rule
  that is true in any language belongs there and only there.

## Go

### Tooling

- Run `go fmt`, never `gofmt`. The module-aware wrapper is the canonical
  invocation — same bytes, but the command is the rule. `go fmt ./...` for the
  whole tree, `go fmt ./<file>` after an edit.
- `go fmt ./...` must print nothing. Then `go build ./cmd/<binary>` and
  `go vet ./...`.
- Tool dependencies are declared in `go.mod`'s `tool` directive and invoked as
  `go tool <name>`, or as `go run <module>` where the module's main package is
  the thing you want. Never `go install` them — that puts the version outside the
  repo.
- Regenerate generated code after an interface change — committing stale mocks
  breaks the project. Where CI can enforce freshness, it regenerates and diffs.

### Dependencies

- **Zero-dependency core.** Add an external dependency only when the standard
  library genuinely cramps the design, not because it is convenient.
- Mature repos: dependency *updates* get their own commit — `go get -u ./... &&
  go mod tidy && go mod vendor`, committed as `vendor: update`, separate from
  any code changes.
- Mature repos: a *new* dependency goes in the commit that first imports it.
  `go mod vendor` only vendors what is actually imported, so a dependency added
  without its consumer either can't be vendored or gets dropped by the next
  vendor operation.
- Greenfield repos: vendor churn may ride along with checkpoint commits.

### Errors and logging

- **`slog.*` throughout.** No `fmt.Println`, no `log.Print*`.
- **Return errors up the stack, wrapped with context** —
  `fmt.Errorf("loading show %q: %w", id, err)`. Panic only where the situation
  is genuinely unrecoverable.

### Interfaces

- **A dependency a caller may need to stand in for gets an interface**, with the
  implementation left unexported and the constructor returning the interface,
  because the concrete type is deliberately not exported to return instead.
- **This is not "prefer interfaces" as a reflex.** One is worth it where
  something actually substitutes for the dependency — a test, a dummy, a second
  implementation — and it costs a layer of indirection everywhere else. A
  concrete type only constructed and used within one package stays concrete.
- **The inverse is the escape hatch**: a method that hands out a concrete
  dependency, like a `Pool()` or `Client()` accessor. Those exist for the few
  callers that genuinely need the concrete thing, usually tests. Adding one to
  avoid introducing an interface is the wrong trade; adding one because a test
  needs it is fine, and the comment should say so.

### Parsing

- HTML goes through `goquery`. Never regex.
- `url.Parse` to parse a URL, `url.URL{}` literals to build one. Never
  `fmt.Sprintf` a URL together.
- **Separate parsing from I/O.** A parser takes an `io.Reader` and returns
  structured data; the caller does the network call. Tests then run against
  saved snapshots with no HTTP mocking.

## Libraries

**The core is zero-dependency.** These are the ones to reach for when the
standard library genuinely does not cover it. They are what the projects
already use, so picking an *alternative* for the same job is a decision to
raise, not one to make quietly — and if you need something not listed here, ask
rather than choosing unilaterally.

**Never pin a version in prose.** The version lives in `go.mod` and nowhere
else; a copy in a document is stale within a week. A major-version suffix *is*
part of the module's identity, so it stays — and where one exists, use the
latest.

**If a project already depends on something else, leave it.** Migrating a
dependency is its own piece of work, not a side effect of the task in hand.

| Need | Library |
|---|---|
| CLI | `github.com/urfave/cli/v3` |
| Test assertions | `github.com/stretchr/testify` |
| Mocks | `go.uber.org/mock` — `mockgen` via the `tool` directive |
| Identifiers | `github.com/google/uuid` |
| Postgres | `github.com/jackc/pgx/v5` |
| SQLite | `modernc.org/sqlite` — pure Go, no cgo |
| Job queue | `github.com/riverqueue/river`, driver `…/riverpgxv5`, UI `riverqueue.com/riverui` |
| GraphQL server | `github.com/99designs/gqlgen` with `github.com/vektah/gqlparser/v2` |
| GraphQL client | `github.com/Khan/genqlient` — see below |
| Data loaders | `github.com/vikstrous/dataloadgen` |
| HTML parsing | `github.com/PuerkitoBio/goquery` |
| Markdown | `github.com/yuin/goldmark` |
| Metrics | `github.com/prometheus/client_golang` |
| CORS | `github.com/rs/cors` |
| Form decoding | `github.com/gorilla/schema` |
| Archives | `github.com/mholt/archives` |
| Git | `github.com/go-git/go-git/v6` |
| MCP servers | `github.com/mark3labs/mcp-go` |
| Retries and backoff | `github.com/cenkalti/backoff/v7` |
| Rate limiting | `github.com/throttled/throttled/v2` |
| Python workers | `github.com/YuminosukeSato/pyproc` |

**GraphQL.** Two clients do the same job. `github.com/Khan/genqlient` is the one
to reach for: it is properly tagged, it declares itself as a `tool` dependency
and runs via `go run`, and it exposes `graphql.Client` as an interface, so the
house `mockgen` convention applies to it. `git.sr.ht/~emersion/gqlclient` does
the same work, but it has no tagged releases — it can only be pinned by commit —
and where it is used today its generator is invoked from a globally installed
binary rather than through the `tool` directive, which is the exact thing that
rule exists to prevent.

## Persistence

### Ownership

- **The framework owns the plumbing**: the connection pool, `WithTransaction`,
  the async worker pool, migrations, the fetch helpers, and the generic
  mappers. **A repo owns its SQL schema and its entity methods.**
- **All database access goes through the persistence interface.** Never raw SQL
  outside the implementation package. The exceptions are narrow and named in
  the repo — a one-shot migration command, a legacy reader kept for an importer,
  and test setup.
- Where a repo re-exports the framework's error values, it re-exports them as
  **aliases**, so `errors.Is(err, persistence.ErrMissingEntity)` still works
  across the boundary. Which ones a given repo re-exports varies; read its
  `persistence/types.go` rather than assuming the set.

### Policy

- **Surrogate keys, never natural keys.** Every table gets an auto-incrementing
  `id BIGSERIAL PRIMARY KEY`; a natural key gets a unique constraint and is used
  for `ON CONFLICT` upserts. Never as the primary key.
- **Any migration or seed is a migration** — not a hand-run script, and not a
  manual fix against a live database.
- **Values cross the persistence boundary plain**, and are parsed in the
  operation layer. No domain logic, and no arithmetic on structured values,
  inside persistence.
- **A state file is complete or it is not written**: nothing partial, and no
  in-progress flags. This is about exported state files, not about status
  columns in a schema, which a table may legitimately have.
- State files are written atomically: export to `.part` and rename, and hold the
  working store in a single WAL transaction.

### Entity methods — the `V{N}` family

Method names carry the **application API version** the repo is on — `V1*`,
`V4*` — the same versioning as `/api/v1`, not a version of the persistence
layer. A new API generation takes a new prefix rather than renaming the old
methods, so both generations can be served at once.

| Verb | Shape | When |
|---|---|---|
| `Get{X}By{Y}Many` | `(ctx, keys) ([]*Record, []error)` | Bulk lookup — **the default** |
| `Get{X}By{Y}` | `(ctx, key) (*Record, error)` | Single entity — only where needed |
| `Add{X}` / `Create{X}` | `(ctx, params) (*Record, error)` | Create |
| `Set{X}` / `Update{X}` | varies | Partial update |
| `Delete{X}` | `(ctx, key) error` | Delete |
| `Upsert{X}` | `(ctx, record) (*Record, error)` | Insert-or-update |
| `List{X}` / `Search{X}` | `(ctx, opts) (*Result, error)` | List with paging and filtering |

Bulk lookup is the primary path; the single-entity getter is the exception, not
the other way round.

### Bulk lookups and the per-key error

- Results are **positionally aligned to the input keys**: one entry per key, a
  `nil` record for an absent key, and **no error** for an absent key. Grouped
  variants return `([][]*Record, []error)` with a `nil` slice per absent key.
- The error slot is **per-key**: on query failure the mapper returns a `nil`
  result slice plus the *same error repeated* `len(keys)` times. The loader reads
  `errors[pos]` for each key, so returning a *shorter* slice is a bug it reports
  as `bug in fetch function`.
- **On success the error slice is `nil`, not `len(keys)` nils.** So `errs[0]`
  panics precisely when everything worked. Index it only behind a length check —
  `if len(errs) > 0 && errs[0] != nil` — or, for a consumer that does not need
  per-key detail, collapse it nil-safely with `errors.Join(errs...)`, which is
  what `dataloadgen`'s own `ErrorSlice.Unwrap` does.
- **When the keys are meaningless** — "just get them all" — fetch once and fan
  the result out with `slices.Repeat(result, len(keys))`, and on failure
  `slices.Repeat([]error{err}, len(keys))`.
- **A `nil` slot means *absent*, and what absent means is per-entity.** It can
  mean a missing entity, or a counter with no rows yet, which consumers render
  as zero rather than treating as missing. Each many-method's contract says
  which — read it rather than assuming.
- The contract is enforced by the framework's `generic.MapSliceByID` and
  `GroupSliceByID`. Read the mapper you are changing — it is what produces the
  positional correspondence.
- Queries batch with `WHERE key = ANY($1)` and `pgtype.FlatArray[T]`.

**Missing entities are deliberately asymmetric, and it is not an oversight.**
A single getter returns `persistence.ErrMissingEntity`; a bulk lookup returns a
`nil` slot. A single-row not-found as a sentinel is the Go convention
(`sql.ErrNoRows`), and it forces the caller to handle it rather than sail past a
`(nil, nil)`. Positionally, the `nil` at the index you are already reading *is*
the signal, and a sentinel there would have to be checked twice.

### Data loaders

The many-method's per-key shape is not a house preference — it is exactly the
batch signature `dataloadgen` wants, so a many-method is handed to the loader
directly, with no adapter:

```go
func NewLoader[KeyT comparable, ValueT any](
    fetch func(ctx context.Context, keys []KeyT) ([]ValueT, []error),
    options ...Option) *Loader[KeyT, ValueT]
```

That is the whole reason the contract is positional and per-key, and why the
persistence layer must not collapse the error slice into a single error.

- **One loader set per request**, built by middleware and fetched from the
  request context, so a batch within a request is deduplicated and a batch
  across requests is not.
- **`Clear` a key before priming it.** `Prime` will not overwrite an entry that
  already exists, so priming over a stale one silently does nothing.
- **A loader may depend on request-scoped state beyond its keys** — the
  authenticated user, for instance — by closing over it when the loader is
  constructed. The keys stay the batch key only.

### Options, Params and results

- **Options structs** drive list and search methods — filtering, pagination,
  sorting — and embed `PagingOptions` and `SortOptions[T]`. Simple getters do
  not need one.
- **Params structs** drive mutations. Use `sql.Null[T]` fields for partial
  updates: non-null sets the column, null leaves it. That avoids zero-value
  writes and supports concurrent partial modification.
- **List and search return a result struct** carrying the records plus a total
  count.
- Persisted record types carry a `-Record` suffix, are plain values, and map
  columns with `db:` struct tags. Mutating a copy persists nothing until an
  explicit call goes through the client.

### Interface structure

Entity interfaces are **unexported, grouped by domain, and embedded** into the
exported generation client, which is itself embedded into the repo's `Client`
alongside `persistence.Client`. Never exported one at a time.

An interface change, its implementations and the regenerated mocks are one
logical change.

### Migrations

Adding a migration means all four of:

1. a new numbered SQL file, `schema_<from>_<to>.sql` — `schema_04_05.sql` takes
   the schema from 4 to 5;
2. a `//go:embed` variable for it;
3. an entry in the migration set's upgrade-path map, **keyed by from-version**,
   with the target version alongside the embedded SQL;
4. bumping the set's current schema version.

The SQL ends with `UPDATE <version-table> SET version = <to> WHERE id = 1;`,
where the version table is named per repo. Spell these out as from and to rather
than as letter pairs — the letters have been used the opposite way round in
different documents, which is a good way to write the wrong number.

`UpgradePath` also carries `PreTX`/`PostTX` hooks, which run **outside** the
migration transaction. They exist for statements that cannot run in the
transaction that adds them — a new enum value cannot be used in the transaction
that creates it.

**Never copy the current schema version into prose.** It lives in the code, and
a copy in a document is wrong within a generation or two.

### Transactions

- `WithTransaction(ctx, rw)` creates a transaction and stores it in the context.
  Individual methods detect and reuse it.
- **Nesting is not allowed.** Calling `WithTransaction` while one is active
  returns `ErrAlreadyInTx`. There are no savepoints. Reuse the ambient
  transaction instead of opening another.
- The ambient transaction is read-only or read-write. An inner read-write
  operation inside a read-only transaction fails with `ErrCannotUpgradeTx`, so
  **choose `rw` at the outermost call.**
- Commit and rollback procs are `persistence.TxProc`. Rollback after a commit is
  a no-op.

### Mocks and generated code

- A mocks package sits beside the interface it serves, with the `//go:generate`
  directive in a hand-written `package.go` and the generated file beside it. What
  the generated file is called is the repo's business.
- Regenerate with `go generate ./...` after any interface change, and squash the
  regenerated mocks into the commit that changed the interface.

### Testing

- **Persistence is tested against a real database**, one temporary schema per
  test — not against mocks. New entity tables and methods get cases in the same
  suite.
- **Tests must run offline.** Use `testdata` snapshots; never hit the network in
  a test.
- **Assert against known values, not patterns.** If a fixture came from a real
  page, test the exact extracted value.
- **Fixture fidelity beats fixture size.** Dump the real thing and commit it;
  do not trim a fixture down to the case you were originally chasing.
- **An assertion that cannot fail is decoration.** Decide what change would
  break a test, then make that change; a test that fails for the wrong reason is
  no better than one that cannot fail.
- Golden files are regenerated only when the rendered output intentionally
  changes, and the regeneration is part of the commit that changed it.
- In a repo that has a test suite, tests are required where they pay — parsers,
  persistence, anything with specced behaviour — and the suite must be green
  before you commit.

## Method

How the work gets done, across all the repos.

- **The code is the source of truth.** When a document and the implementation
  disagree, the implementation is right. Update the doc if the intent has
  changed; do not "fix" the code to match the prose.
- **Read the reference implementation's source first** — before theorising, and
  not merely to confirm a theory you already hold.
- **A clean output is not proof of correct code.** Verify against ground truth —
  a runtime trace, the actual bytes, the row in the database.
- **When in doubt, instrument and run rather than theorise.**
- **If something looks wrong, find out why.** Never ignore an anomaly.
- **No hacks, no filtering, no suppression, no workarounds patched onto wrong
  foundations.** If the foundation is wrong, say so.
- **Independent verification beats self-review.** For anything load-bearing, run
  several independent review passes and reconcile them; agreement across
  independent auditors is worth more than one careful reading.
- **Reverse verification finds spec gaps.** Have an agent implement from the
  specification alone, without the code, and see what it has to invent.
