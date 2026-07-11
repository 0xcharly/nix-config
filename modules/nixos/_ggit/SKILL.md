# ggit

A read-only, dark-mode web viewer for a
[python-github-backup](https://github.com/josegonzalez/python-github-backup)
output tree. Every repository it serves is a mirror of
`github.com/<owner>/<repo>`. Written in Go with no runtime dependencies
beyond the `git` binary; HTML is rendered server-side with `html/template`,
styled by the Tailwind browser CDN build, with `hx-boost` (htmx) navigation.

Deployment lives in `../selfhosted-ggit.nix`: a systemd service on tank
serving `/tank/backups/github`, exposed on the tailnet and registered with
the reverse proxy and gatus. That module also exposes the package as
`perSystem.packages.ggit` (`nix build .#ggit`).

## Layout

- `main.go` — flag parsing (`--listen`, `--port`, `--git`, one positional
  `<backup-root>`), startup scan, `http.Server`.
- `internal/backup/` — `Scan(root)` discovers owners/repos from the backup
  tree; enriches descriptions from `<root>/ggit.toml` (`[descriptions]`
  table, highest precedence), then `<owner>/account/watched.json`, then
  `starred.json`. All enrichment is best-effort.
- `internal/gitcmd/` — `Git.Run(ctx, gitDir, args...)`: shells out to git
  with `--git-dir`, color disabled, `LC_ALL=C`. Stdout capped at 8 MiB
  (`ErrTruncated`); failures return `*GitError` with exit code and stderr.
  No libgit2/go-git binding — every page is parsed git plumbing output.
- `internal/web/` — routing, git output parsing, rendering.
  - `handlers.go` — one `handle<Page>` per route, organized in `// --- page ---`
    sections. Routes (Go 1.22 method patterns): `/{$}`,
    `/{owner}/{repo}/{$,about,summary,refs,log,tree,commit}`.
  - `templates.go` — `//go:embed templates/*.html`; each page template is
    parsed against `layout.html`. Helpers: `reltime` (cgit-style ages),
    `bytesize`, `tabs`.
  - `templates/` — Tailwind utility classes inline; link convention is
    `text-blue-200 hover:underline`.
  - `web_test.go` — httptest against fixture repos built by shelling out to
    git (bare mirrors with pinned author/committer dates).

## Invariants

- **Stateless**: every request re-scans the backup root and shells out to
  git. No cache, no writes — the server never mutates the backup tree.
- **Path safety**: request `{owner}/{repo}` values are matched against the
  scanned set (`resolveRepo`), never joined into filesystem paths.
- **Bounded output**: `pageSize = 100`, `requestTimeout = 10s`,
  `maxBlobRender = 1 MiB`, git stdout ≤ 8 MiB (oversized diffs render a
  "truncated" notice instead of failing).
- **GitHub provenance**: every repo is a GitHub mirror by construction, so
  GitHub backlinks (e.g. on the commit page) are rendered unconditionally.

## Backup tree layout

```
<root>/
  ggit.toml                                  # optional [descriptions]
  <owner>/
    account/{watched,starred}.json           # optional descriptions
    repositories/<repo>/repository[/.git]    # bare git dir (or non-bare fallback)
```

`Scan` skips anything without a readable `HEAD`; directories that don't
match this shape are silently ignored.

## Build and test

There is no `go` binary in the dev shell. Build and test through Nix — the
`buildGoModule` checkPhase runs `go test ./...` (git provided via
`nativeCheckInputs`):

```sh
nix build .#ggit --print-out-paths
```

- New files must be `git add -N`-ed or the flake won't see them.
- Changing `go.mod`/`go.sum` invalidates `vendorHash` in `default.nix`.
- `format` (treefmt) does not cover Go; keep edits gofmt-style (tabs) by
  hand.

## Running locally

```sh
./result/bin/ggit --listen 127.0.0.1 --port 9917 <backup-root>
```

Two options for `<backup-root>`:

- **Real data on demand**: the user can mount a copy of the production
  backups (read-only) at `/tmp/github-backup` — ask for it when a change
  benefits from real-world repos. Don't assume it is mounted; the directory
  may be empty between sessions, and the startup log line
  (`N owners, M repositories`) tells you whether the scan found anything.
- **Synthetic fixture**: clone any repo into the expected shape, e.g.

  ```sh
  git clone --bare --no-hardlinks . /tmp/ggit-e2e/o/r/repositories/r/repository
  ```

Smoke-check pages with `curl` against `/{owner}/{repo}/log`, `tree`,
`commit?id=<sha>`, etc. Kill the server when done.
