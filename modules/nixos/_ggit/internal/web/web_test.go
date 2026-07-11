package web

import (
	"bytes"
	"html"
	"log"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/0xcharly/nix-config/ggit/internal/gitcmd"
)

const (
	fixtureSubject  = "add fixture files"
	fixtureReadme   = "# demo fixture readme"
	fixtureFileBody = "hello fixture file"
)

type fixture struct {
	root    string
	gitBin  string
	commit  string // full hash of the demo repo's only commit
	handler http.Handler
}

func runGit(t *testing.T, dir string, args ...string) string {
	t.Helper()
	gitBin, err := exec.LookPath("git")
	if err != nil {
		t.Fatalf("git not found in PATH: %v", err)
	}
	cmd := exec.Command(gitBin, args...)
	cmd.Dir = dir
	cmd.Env = append(os.Environ(),
		"GIT_AUTHOR_NAME=Fixture Author",
		"GIT_AUTHOR_EMAIL=fixture@example.com",
		"GIT_AUTHOR_DATE=2024-01-02T03:04:05Z",
		"GIT_COMMITTER_NAME=Fixture Author",
		"GIT_COMMITTER_EMAIL=fixture@example.com",
		"GIT_COMMITTER_DATE=2024-01-02T03:04:05Z",
	)
	out, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("git %v: %v\n%s", args, err, out)
	}
	return strings.TrimSpace(string(out))
}

// mirrorRepo creates <root>/<owner>/repositories/<name>/repository as a bare
// mirror of a fresh worktree containing files.
func mirrorRepo(t *testing.T, root, owner, name string, files map[string]string) string {
	t.Helper()
	work := t.TempDir()
	runGit(t, work, "init", "-b", "main")
	for rel, body := range files {
		p := filepath.Join(work, rel)
		if err := os.MkdirAll(filepath.Dir(p), 0o755); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(p, []byte(body), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	runGit(t, work, "add", ".")
	runGit(t, work, "commit", "-m", fixtureSubject)
	hash := runGit(t, work, "rev-parse", "HEAD")

	dst := filepath.Join(root, owner, "repositories", name, "repository")
	if err := os.MkdirAll(filepath.Dir(dst), 0o755); err != nil {
		t.Fatal(err)
	}
	runGit(t, work, "clone", "--mirror", work, dst)
	return hash
}

func newFixture(t *testing.T) *fixture {
	t.Helper()
	gitBin, err := exec.LookPath("git")
	if err != nil {
		t.Fatalf("git not found in PATH: %v", err)
	}
	root := t.TempDir()
	hash := mirrorRepo(t, root, "testowner", "demo", map[string]string{
		"README.md":     fixtureReadme + "\n",
		"dir/file.txt":  fixtureFileBody + "\n",
		"docs/guide.md": "# guide\n\nsee [readme](../README.md), [ext](https://example.com/x)\n\n![logo](img/logo.png) ![ext](https://example.com/e.png)\n\n<script>alert(1)</script>\n",
	})
	mirrorRepo(t, root, "testowner", "noreadme", map[string]string{
		"x.txt": "no readme here\n",
	})

	account := filepath.Join(root, "testowner", "account")
	if err := os.MkdirAll(account, 0o755); err != nil {
		t.Fatal(err)
	}
	watched := `[{"full_name":"testowner/demo","description":"fixture repo"}]`
	if err := os.WriteFile(filepath.Join(account, "watched.json"), []byte(watched), 0o644); err != nil {
		t.Fatal(err)
	}

	srv := NewServer(root, gitcmd.Git{Bin: gitBin})
	return &fixture{root: root, gitBin: gitBin, commit: hash, handler: srv.Handler()}
}

func (f *fixture) get(t *testing.T, url string) *httptest.ResponseRecorder {
	t.Helper()
	req := httptest.NewRequest(http.MethodGet, url, nil)
	rec := httptest.NewRecorder()
	f.handler.ServeHTTP(rec, req)
	return rec
}

func (f *fixture) mustGet(t *testing.T, url string, wantStatus int) string {
	t.Helper()
	rec := f.get(t, url)
	if rec.Code != wantStatus {
		t.Fatalf("GET %s = %d, want %d\nbody: %.2000s", url, rec.Code, wantStatus, rec.Body.String())
	}
	return rec.Body.String()
}

func captureLog(t *testing.T) *bytes.Buffer {
	t.Helper()
	var buf bytes.Buffer
	log.SetOutput(&buf)
	t.Cleanup(func() { log.SetOutput(os.Stderr) })
	return &buf
}

func TestIndex(t *testing.T) {
	f := newFixture(t)
	body := f.mustGet(t, "/", http.StatusOK)
	for _, want := range []string{"testowner", "demo", "fixture repo"} {
		if !strings.Contains(body, want) {
			t.Errorf("index missing %q", want)
		}
	}
}

func TestGgitTomlPrecedence(t *testing.T) {
	f := newFixture(t)
	tomlPath := filepath.Join(f.root, "ggit.toml")

	if err := os.WriteFile(tomlPath, []byte("[descriptions]\n\"testowner/demo\" = \"handwritten wins\"\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	body := f.mustGet(t, "/", http.StatusOK)
	if !strings.Contains(body, "handwritten wins") {
		t.Error("ggit.toml description not shown")
	}
	if strings.Contains(body, "fixture repo") {
		t.Error("watched.json description should be overridden by ggit.toml")
	}

	buf := captureLog(t)
	if err := os.WriteFile(tomlPath, []byte("[descriptions\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	body = f.mustGet(t, "/", http.StatusOK)
	if !strings.Contains(body, "fixture repo") {
		t.Error("malformed ggit.toml should fall back to watched.json")
	}
	if !strings.Contains(buf.String(), "ERROR reading") {
		t.Errorf("expected ERROR reading log line, got:\n%s", buf.String())
	}
}

func TestSummary(t *testing.T) {
	f := newFixture(t)
	body := f.mustGet(t, "/testowner/demo/summary", http.StatusOK)
	if !strings.Contains(body, fixtureSubject) {
		t.Error("summary missing commit subject")
	}
	if !strings.Contains(body, "main") {
		t.Error("summary missing branch name")
	}
}

func TestRepoRootRedirect(t *testing.T) {
	f := newFixture(t)
	rec := f.get(t, "/testowner/demo/")
	if rec.Code != http.StatusFound {
		t.Fatalf("GET /testowner/demo/ = %d, want 302", rec.Code)
	}
	if loc := rec.Header().Get("Location"); loc != "/testowner/demo/summary" {
		t.Errorf("redirect location = %q", loc)
	}
}

func TestAbout(t *testing.T) {
	f := newFixture(t)
	body := f.mustGet(t, "/testowner/demo/about", http.StatusOK)
	if !strings.Contains(body, "demo fixture readme") {
		t.Error("about missing README content")
	}
	if !strings.Contains(body, `<h1 id="demo-fixture-readme">demo fixture readme</h1>`) {
		t.Error("about README not rendered as HTML")
	}
	if !strings.Contains(body, `href="/testowner/demo/tree?path=README.md&amp;source=1"`) {
		t.Error("about missing source link")
	}
	if !strings.Contains(body, `href="/testowner/demo/raw?path=README.md" hx-boost="false"`) {
		t.Error("about missing unboosted raw link")
	}
	body = f.mustGet(t, "/testowner/noreadme/about", http.StatusOK)
	if !strings.Contains(body, "No README") {
		t.Error("about for repo without README should say so")
	}
}

func TestMarkdownBlob(t *testing.T) {
	f := newFixture(t)
	body := f.mustGet(t, "/testowner/demo/tree?path=docs/guide.md", http.StatusOK)
	if !strings.Contains(body, `<h1 id="guide">guide</h1>`) {
		t.Error("markdown blob not rendered as HTML")
	}
	if !strings.Contains(body, `href="/testowner/demo/tree?path=README.md"`) {
		t.Error("relative link not rewritten to tree URL")
	}
	if !strings.Contains(body, `href="https://example.com/x"`) {
		t.Error("absolute link should be untouched")
	}
	if strings.Contains(body, "<script>alert") {
		t.Error("raw HTML must not pass through")
	}
	if !strings.Contains(body, "source=1") {
		t.Error("rendered view missing source toggle")
	}
	if !strings.Contains(body, `href="/testowner/demo/raw?path=docs%2Fguide.md"`) {
		t.Error("rendered view missing raw file link")
	}
	if !strings.Contains(body, `src="/testowner/demo/raw?path=docs%2Fimg%2Flogo.png"`) {
		t.Error("relative image src not rewritten to raw URL")
	}
	if !strings.Contains(body, `src="https://example.com/e.png"`) {
		t.Error("absolute image src should be untouched")
	}

	body = f.mustGet(t, "/testowner/demo/tree?path=docs/guide.md&source=1", http.StatusOK)
	if !strings.Contains(body, "[readme](../README.md)") {
		t.Error("source view should show markdown source")
	}
	if !strings.Contains(body, ">rendered</a>") {
		t.Error("source view missing rendered toggle")
	}
}

func TestRawFile(t *testing.T) {
	f := newFixture(t)

	rec := f.get(t, "/testowner/demo/raw?path=dir/file.txt")
	if rec.Code != http.StatusOK {
		t.Fatalf("raw file = %d, want 200", rec.Code)
	}
	if got := rec.Body.String(); got != fixtureFileBody+"\n" {
		t.Errorf("raw body = %q, want file content verbatim", got)
	}
	if ct := rec.Header().Get("Content-Type"); ct != "text/plain; charset=utf-8" {
		t.Errorf("raw text Content-Type = %q", ct)
	}
	if rec.Header().Get("X-Content-Type-Options") != "nosniff" {
		t.Error("raw response missing nosniff")
	}

	// Markdown must not come back as text/html either: same text/plain policy.
	rec = f.get(t, "/testowner/demo/raw?path=docs/guide.md")
	if ct := rec.Header().Get("Content-Type"); !strings.HasPrefix(ct, "text/plain") {
		t.Errorf("raw markdown Content-Type = %q, want text/plain", ct)
	}

	// Errors are bare plain text, raw.githubusercontent-style — never the
	// HTML layout (which hx-boost would also swap into the page).
	for _, u := range []string{
		"/testowner/demo/raw?path=does/not/exist",
		"/testowner/demo/raw?path=dir", // a directory
		"/testowner/demo/raw",          // no path
		"/testowner/nosuchrepo/raw?path=x",
		"/testowner/demo/raw?path=dir/file.txt&ref=nosuchref",
	} {
		rec = f.get(t, u)
		if rec.Code != http.StatusNotFound {
			t.Errorf("GET %s = %d, want 404", u, rec.Code)
		}
		if got := rec.Body.String(); got != "404: Not Found\n" {
			t.Errorf("GET %s body = %q, want bare status line", u, got)
		}
		if ct := rec.Header().Get("Content-Type"); ct != "text/plain; charset=utf-8" {
			t.Errorf("GET %s Content-Type = %q", u, ct)
		}
	}

	// Every blob preview page links to the raw endpoint, unboosted so the
	// browser navigates instead of htmx swapping text into the layout.
	body := f.mustGet(t, "/testowner/demo/tree?path=dir/file.txt", http.StatusOK)
	if !strings.Contains(body, `href="/testowner/demo/raw?path=dir%2Ffile.txt" hx-boost="false"`) {
		t.Error("line-view blob page missing unboosted raw file link")
	}
}

func TestRefs(t *testing.T) {
	f := newFixture(t)
	body := f.mustGet(t, "/testowner/demo/refs", http.StatusOK)
	if !strings.Contains(body, "main") {
		t.Error("refs missing branch name")
	}
}

func TestLog(t *testing.T) {
	f := newFixture(t)
	body := f.mustGet(t, "/testowner/demo/log", http.StatusOK)
	if !strings.Contains(body, fixtureSubject) {
		t.Error("log missing commit subject")
	}
}

func TestTree(t *testing.T) {
	f := newFixture(t)
	body := f.mustGet(t, "/testowner/demo/tree", http.StatusOK)
	for _, want := range []string{"dir", "README.md"} {
		if !strings.Contains(body, want) {
			t.Errorf("tree listing missing %q", want)
		}
	}
	body = f.mustGet(t, "/testowner/demo/tree?path=dir", http.StatusOK)
	if !strings.Contains(body, "file.txt") {
		t.Error("subdirectory listing missing file.txt")
	}
	body = f.mustGet(t, "/testowner/demo/tree?path=dir/file.txt", http.StatusOK)
	if !strings.Contains(body, fixtureFileBody) {
		t.Error("blob view missing file content")
	}
}

func TestCommit(t *testing.T) {
	f := newFixture(t)
	body := f.mustGet(t, "/testowner/demo/commit?id="+f.commit, http.StatusOK)
	if !strings.Contains(body, f.commit) {
		t.Error("commit page missing full hash")
	}
	// html/template escapes "+" as &#43;; compare against the visible text.
	if !strings.Contains(html.UnescapeString(body), "+"+fixtureFileBody) {
		t.Error("commit page missing added diff line")
	}
	if !strings.Contains(body, "https://github.com/testowner/demo/commit/"+f.commit) {
		t.Error("commit page missing GitHub link")
	}
}

func TestNotFound(t *testing.T) {
	f := newFixture(t)
	f.mustGet(t, "/nope/nope/summary", http.StatusNotFound)
	f.mustGet(t, "/testowner/demo/tree?path=../../etc", http.StatusNotFound)
	f.mustGet(t, "/testowner/demo/commit?id=doesnotexist", http.StatusNotFound)
	f.mustGet(t, "/testowner/demo/log?ref=doesnotexist", http.StatusNotFound)
}

func TestRequestLogging(t *testing.T) {
	f := newFixture(t)
	buf := captureLog(t)

	f.mustGet(t, "/testowner/demo/summary", http.StatusOK)
	f.mustGet(t, "/nope/nope/summary", http.StatusNotFound)

	logs := buf.String()
	if !strings.Contains(logs, "/testowner/demo/summary -> 200") {
		t.Errorf("missing access log for 200, got:\n%s", logs)
	}
	if !strings.Contains(logs, "/nope/nope/summary -> 404") {
		t.Errorf("missing access log for 404, got:\n%s", logs)
	}
}

func TestGitFailureLogsDetail(t *testing.T) {
	f := newFixture(t)
	// Corrupt the repo: garbage HEAD makes git refuse the git dir entirely,
	// while the scanner (which only checks HEAD presence) still lists it.
	head := filepath.Join(f.root, "testowner", "repositories", "demo", "repository", "HEAD")
	if err := os.WriteFile(head, []byte("garbage\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	buf := captureLog(t)

	f.mustGet(t, "/testowner/demo/summary", http.StatusInternalServerError)

	logs := buf.String()
	if !strings.Contains(logs, "ERROR") {
		t.Fatalf("expected ERROR log line, got:\n%s", logs)
	}
	if !strings.Contains(logs, "git") || !strings.Contains(logs, "exit") {
		t.Errorf("ERROR line should contain git argv and exit code, got:\n%s", logs)
	}
}
