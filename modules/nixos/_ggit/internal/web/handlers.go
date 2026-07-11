// Package web implements the ggit HTTP server: routing, git output parsing,
// and HTML rendering.
package web

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"html/template"
	"log"
	"net/http"
	"net/url"
	"path"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/0xcharly/nix-config/ggit/internal/backup"
	"github.com/0xcharly/nix-config/ggit/internal/gitcmd"
)

const (
	pageSize       = 100
	requestTimeout = 10 * time.Second
	maxBlobRender  = 1 << 20 // 1 MiB
)

// Server serves the read-only backup viewer. It is stateless: every request
// re-scans the backup root and shells out to git.
type Server struct {
	root string
	git  gitcmd.Git
	tmpl map[string]*template.Template
}

func NewServer(root string, git gitcmd.Git) *Server {
	return &Server{root: root, git: git, tmpl: parseTemplates()}
}

func (s *Server) Handler() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /{$}", s.handleIndex)
	mux.HandleFunc("GET /{owner}/{repo}/{$}", s.handleRepoRoot)
	mux.HandleFunc("GET /{owner}/{repo}/about", s.handleAbout)
	mux.HandleFunc("GET /{owner}/{repo}/summary", s.handleSummary)
	mux.HandleFunc("GET /{owner}/{repo}/refs", s.handleRefs)
	mux.HandleFunc("GET /{owner}/{repo}/log", s.handleLog)
	mux.HandleFunc("GET /{owner}/{repo}/tree", s.handleTree)
	mux.HandleFunc("GET /{owner}/{repo}/raw", s.handleRaw)
	mux.HandleFunc("GET /{owner}/{repo}/commit", s.handleCommit)
	return logRequests(mux)
}

// --- request logging ---

type statusRecorder struct {
	http.ResponseWriter
	status int
	bytes  int
}

func (r *statusRecorder) WriteHeader(code int) {
	r.status = code
	r.ResponseWriter.WriteHeader(code)
}

func (r *statusRecorder) Write(b []byte) (int, error) {
	n, err := r.ResponseWriter.Write(b)
	r.bytes += n
	return n, err
}

func logRequests(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(rec, r)
		log.Printf("%s %s %s -> %d %dB %s",
			r.RemoteAddr, r.Method, r.URL.RequestURI(), rec.status, rec.bytes, time.Since(start))
	})
}

// --- shared page plumbing ---

type page struct {
	Title     string
	Owner     string
	Repo      string
	ActiveTab string
}

type errorData struct {
	page
	Status  int
	Message string
}

func (s *Server) render(w http.ResponseWriter, status int, name string, data any) {
	t, ok := s.tmpl[name]
	if !ok {
		log.Printf("ERROR unknown template %q", name)
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	var buf bytes.Buffer
	if err := t.ExecuteTemplate(&buf, "layout.html", data); err != nil {
		log.Printf("ERROR rendering %s: %v", name, err)
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.WriteHeader(status)
	_, _ = buf.WriteTo(w)
}

func (s *Server) notFound(w http.ResponseWriter, pg page, msg string) {
	pg.Title = "not found · ggit"
	s.render(w, http.StatusNotFound, "error", errorData{page: pg, Status: http.StatusNotFound, Message: msg})
}

// fail logs full git diagnostics and responds with a generic 500 page.
func (s *Server) fail(w http.ResponseWriter, r *http.Request, pg page, err error) {
	var ge *gitcmd.GitError
	if errors.As(err, &ge) {
		log.Printf("ERROR %s %s: git %v (exit %d): %s",
			r.Method, r.URL.RequestURI(), ge.Args, ge.ExitCode, ge.Stderr)
	} else {
		log.Printf("ERROR %s %s: %v", r.Method, r.URL.RequestURI(), err)
	}
	pg.Title = "internal error · ggit"
	s.render(w, http.StatusInternalServerError, "error",
		errorData{page: pg, Status: http.StatusInternalServerError, Message: "internal error"})
}

func repoURL(owner, repo, pageName string, q url.Values) string {
	u := "/" + url.PathEscape(owner) + "/" + url.PathEscape(repo) + "/" + pageName
	if len(q) > 0 {
		u += "?" + q.Encode()
	}
	return u
}

// resolveRepo maps {owner}/{repo} path values onto the scanned backup set.
// Request strings are never joined into filesystem paths directly.
func (s *Server) resolveRepo(w http.ResponseWriter, r *http.Request) (backup.Repo, bool) {
	owner, name := r.PathValue("owner"), r.PathValue("repo")
	pg := page{Owner: owner, Repo: name}
	owners, err := backup.Scan(s.root)
	if err != nil {
		s.fail(w, r, pg, err)
		return backup.Repo{}, false
	}
	for _, o := range owners {
		if o.Name != owner {
			continue
		}
		for _, repo := range o.Repos {
			if repo.Name == name {
				return repo, true
			}
		}
	}
	s.notFound(w, pg, fmt.Sprintf("Unknown repository %s/%s.", owner, name))
	return backup.Repo{}, false
}

func (s *Server) repoPage(repo backup.Repo, tab string) page {
	return page{
		Title:     repo.FullName() + " · " + tab,
		Owner:     repo.Owner,
		Repo:      repo.Name,
		ActiveTab: tab,
	}
}

// defaultRef returns the ref repo pages use when ?ref= is absent: the HEAD
// branch if it resolves to a commit, else the first branch, else "" (empty
// repository).
func (s *Server) defaultRef(ctx context.Context, gitDir string) (string, error) {
	if out, err := s.git.Run(ctx, gitDir, "symbolic-ref", "--short", "HEAD"); err == nil {
		ref := strings.TrimSpace(string(out))
		if ref != "" {
			if _, err := s.git.Run(ctx, gitDir, "rev-parse", "--verify", "--quiet", "--end-of-options", ref+"^{commit}"); err == nil {
				return ref, nil
			}
		}
	}
	out, err := s.git.Run(ctx, gitDir, "for-each-ref", "--count=1", "--format=%(refname:short)", "refs/heads")
	if err != nil {
		return "", err
	}
	return strings.TrimSpace(string(out)), nil
}

// resolveRef validates ?ref= (or falls back to defaultRef). Return values:
// ref name, ok. On !ok a response has already been written: 404 for an
// invalid explicit ref, an "empty repository" notice page otherwise.
func (s *Server) resolveRef(ctx context.Context, w http.ResponseWriter, r *http.Request, repo backup.Repo, pg page) (string, bool) {
	if ref := r.URL.Query().Get("ref"); ref != "" {
		if _, err := s.git.Run(ctx, repo.GitDir, "rev-parse", "--verify", "--quiet", "--end-of-options", ref+"^{commit}"); err != nil {
			s.notFound(w, pg, fmt.Sprintf("Unknown ref %q.", ref))
			return "", false
		}
		return ref, true
	}
	ref, err := s.defaultRef(ctx, repo.GitDir)
	if err != nil {
		s.fail(w, r, pg, err)
		return "", false
	}
	if ref == "" {
		pg.Title = repo.FullName() + " · empty"
		s.render(w, http.StatusOK, "error", errorData{page: pg, Message: "Empty repository."})
		return "", false
	}
	return ref, true
}

// --- git output parsing ---

var nulSep = []byte{0}

type refRow struct {
	Name, Subject, Author, CommitURL string
	Time                             int64
}

const refFormat = "%(refname:short)%00%(objectname)%00%(committerdate:unix)%00%(subject)%00%(authorname)"
const tagFormat = "%(refname:short)%00%(objectname)%00%(creatordate:unix)%00%(subject)%00%(authorname)"

func parseRefRows(out []byte, owner, repo string) []refRow {
	var rows []refRow
	for _, line := range bytes.Split(bytes.TrimSuffix(out, []byte{'\n'}), []byte{'\n'}) {
		f := bytes.Split(line, nulSep)
		if len(f) < 5 {
			continue
		}
		t, _ := strconv.ParseInt(string(f[2]), 10, 64)
		rows = append(rows, refRow{
			Name:      string(f[0]),
			Subject:   string(f[3]),
			Author:    string(f[4]),
			Time:      t,
			CommitURL: repoURL(owner, repo, "commit", url.Values{"id": {string(f[1])}}),
		})
	}
	return rows
}

type commitRow struct {
	Abbrev, Subject, Author, CommitURL string
	Time                               int64
}

const logFormat = "%H%x00%h%x00%at%x00%an%x00%s"

func parseLogZ(out []byte, owner, repo string) []commitRow {
	fields := bytes.Split(out, nulSep)
	var rows []commitRow
	for i := 0; i+4 < len(fields); i += 5 {
		t, _ := strconv.ParseInt(string(fields[i+2]), 10, 64)
		rows = append(rows, commitRow{
			Abbrev:    string(fields[i+1]),
			Subject:   string(fields[i+4]),
			Author:    string(fields[i+3]),
			Time:      t,
			CommitURL: repoURL(owner, repo, "commit", url.Values{"id": {string(fields[i])}}),
		})
	}
	return rows
}

type lsEntry struct {
	Mode, Type, Hash, Size, Name string
}

// parseLsTree parses `ls-tree -l -z` records: "<mode> <type> <hash> <size>\t<name>",
// NUL-terminated.
func parseLsTree(out []byte) []lsEntry {
	var entries []lsEntry
	for _, rec := range bytes.Split(out, nulSep) {
		tab := bytes.IndexByte(rec, '\t')
		if tab < 0 {
			continue
		}
		meta := strings.Fields(string(rec[:tab]))
		if len(meta) < 4 {
			continue
		}
		entries = append(entries, lsEntry{
			Mode: meta[0], Type: meta[1], Hash: meta[2], Size: meta[3],
			Name: string(rec[tab+1:]),
		})
	}
	return entries
}

// --- index ---

type indexRepo struct {
	Name, FullName, Description, URL string
	Updated                          int64
}

type indexSection struct {
	Owner string
	Repos []indexRepo
}

type indexData struct {
	page
	Sections         []indexSection
	PrevURL, NextURL string
}

func indexURL(pageNum int) string {
	if pageNum <= 1 {
		return "/"
	}
	return "/?page=" + strconv.Itoa(pageNum)
}

func (s *Server) handleIndex(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), requestTimeout)
	defer cancel()

	pg := page{Title: "github backups"}
	owners, err := backup.Scan(s.root)
	if err != nil {
		s.fail(w, r, pg, err)
		return
	}

	pageNum, _ := strconv.Atoi(r.URL.Query().Get("page"))
	if pageNum < 1 {
		pageNum = 1
	}

	var flat []backup.Repo
	for _, o := range owners {
		flat = append(flat, o.Repos...)
	}
	start := (pageNum - 1) * pageSize
	end := min(start+pageSize, len(flat))
	if start > end {
		start, end = 0, 0
	}
	slice := flat[start:end]

	// Freshness only for the repos on this page, bounded worker pool.
	updated := make([]int64, len(slice))
	sem := make(chan struct{}, 16)
	var wg sync.WaitGroup
	for i, repo := range slice {
		wg.Add(1)
		go func() {
			defer wg.Done()
			sem <- struct{}{}
			defer func() { <-sem }()
			updated[i] = s.lastCommitUnix(ctx, repo.GitDir)
		}()
	}
	wg.Wait()

	data := indexData{page: pg}
	if pageNum > 1 {
		data.PrevURL = indexURL(pageNum - 1)
	}
	if end < len(flat) {
		data.NextURL = indexURL(pageNum + 1)
	}
	for i, repo := range slice {
		row := indexRepo{
			Name:        repo.Name,
			FullName:    repo.FullName(),
			Description: repo.Description,
			URL:         repoURL(repo.Owner, repo.Name, "summary", nil),
			Updated:     updated[i],
		}
		if n := len(data.Sections); n == 0 || data.Sections[n-1].Owner != repo.Owner {
			data.Sections = append(data.Sections, indexSection{Owner: repo.Owner})
		}
		last := &data.Sections[len(data.Sections)-1]
		last.Repos = append(last.Repos, row)
	}
	s.render(w, http.StatusOK, "index", data)
}

func (s *Server) lastCommitUnix(ctx context.Context, gitDir string) int64 {
	for _, refs := range []string{"refs/heads", "refs/tags"} {
		out, err := s.git.Run(ctx, gitDir, "for-each-ref",
			"--sort=-committerdate", "--count=1", "--format=%(committerdate:unix)", refs)
		if err != nil {
			return 0
		}
		if t := strings.TrimSpace(string(out)); t != "" {
			if n, err := strconv.ParseInt(t, 10, 64); err == nil {
				return n
			}
		}
	}
	return 0
}

// --- repo pages ---

func (s *Server) handleRepoRoot(w http.ResponseWriter, r *http.Request) {
	repo, ok := s.resolveRepo(w, r)
	if !ok {
		return
	}
	http.Redirect(w, r, repoURL(repo.Owner, repo.Name, "summary", nil), http.StatusFound)
}

type summaryData struct {
	page
	Branches []refRow
	Tags     []refRow
	Commits  []commitRow
}

func (s *Server) handleSummary(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), requestTimeout)
	defer cancel()
	repo, ok := s.resolveRepo(w, r)
	if !ok {
		return
	}
	pg := s.repoPage(repo, "summary")
	ref, ok := s.resolveRef(ctx, w, r, repo, pg)
	if !ok {
		return
	}

	branches, err := s.git.Run(ctx, repo.GitDir, "for-each-ref",
		"--sort=-committerdate", "--count=10", "--format="+refFormat, "refs/heads")
	if err != nil {
		s.fail(w, r, pg, err)
		return
	}
	tags, err := s.git.Run(ctx, repo.GitDir, "for-each-ref",
		"--sort=-creatordate", "--count=10", "--format="+tagFormat, "refs/tags")
	if err != nil {
		s.fail(w, r, pg, err)
		return
	}
	commits, err := s.git.Run(ctx, repo.GitDir, "log",
		"--format="+logFormat, "-z", "--max-count=10", ref)
	if err != nil {
		s.fail(w, r, pg, err)
		return
	}

	s.render(w, http.StatusOK, "summary", summaryData{
		page:     pg,
		Branches: parseRefRows(branches, repo.Owner, repo.Name),
		Tags:     parseRefRows(tags, repo.Owner, repo.Name),
		Commits:  parseLogZ(commits, repo.Owner, repo.Name),
	})
}

type aboutData struct {
	page
	HasReadme bool
	Readme    template.HTML
}

func (s *Server) handleAbout(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), requestTimeout)
	defer cancel()
	repo, ok := s.resolveRepo(w, r)
	if !ok {
		return
	}
	pg := s.repoPage(repo, "about")
	ref, ok := s.resolveRef(ctx, w, r, repo, pg)
	if !ok {
		return
	}
	data := aboutData{page: pg}
	if out, err := s.git.Run(ctx, repo.GitDir, "cat-file", "blob", ref+":README.md"); err == nil {
		data.HasReadme = true
		res := mdResolver{owner: repo.Owner, repo: repo.Name}
		if r.URL.Query().Get("ref") != "" {
			res.refParam = url.Values{"ref": {ref}}
		}
		data.Readme = markdownHTML(out, res)
	}
	s.render(w, http.StatusOK, "about", data)
}

type refsData struct {
	page
	Branches []refRow
	Tags     []refRow
}

func (s *Server) handleRefs(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), requestTimeout)
	defer cancel()
	repo, ok := s.resolveRepo(w, r)
	if !ok {
		return
	}
	pg := s.repoPage(repo, "refs")
	if _, ok := s.resolveRef(ctx, w, r, repo, pg); !ok {
		return
	}

	branches, err := s.git.Run(ctx, repo.GitDir, "for-each-ref",
		"--sort=-committerdate", "--format="+refFormat, "refs/heads")
	if err != nil {
		s.fail(w, r, pg, err)
		return
	}
	tags, err := s.git.Run(ctx, repo.GitDir, "for-each-ref",
		"--sort=-creatordate", "--format="+tagFormat, "refs/tags")
	if err != nil {
		s.fail(w, r, pg, err)
		return
	}
	s.render(w, http.StatusOK, "refs", refsData{
		page:     pg,
		Branches: parseRefRows(branches, repo.Owner, repo.Name),
		Tags:     parseRefRows(tags, repo.Owner, repo.Name),
	})
}

type logData struct {
	page
	RefName          string
	Commits          []commitRow
	PrevURL, NextURL string
}

func (s *Server) handleLog(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), requestTimeout)
	defer cancel()
	repo, ok := s.resolveRepo(w, r)
	if !ok {
		return
	}
	pg := s.repoPage(repo, "log")
	ref, ok := s.resolveRef(ctx, w, r, repo, pg)
	if !ok {
		return
	}
	pageNum, _ := strconv.Atoi(r.URL.Query().Get("page"))
	if pageNum < 1 {
		pageNum = 1
	}

	out, err := s.git.Run(ctx, repo.GitDir, "log",
		"--format="+logFormat, "-z",
		fmt.Sprintf("--max-count=%d", pageSize+1),
		fmt.Sprintf("--skip=%d", (pageNum-1)*pageSize),
		ref)
	if err != nil {
		s.fail(w, r, pg, err)
		return
	}
	rows := parseLogZ(out, repo.Owner, repo.Name)

	logURL := func(p int) string {
		q := url.Values{}
		if r.URL.Query().Get("ref") != "" {
			q.Set("ref", ref)
		}
		if p > 1 {
			q.Set("page", strconv.Itoa(p))
		}
		return repoURL(repo.Owner, repo.Name, "log", q)
	}
	data := logData{page: pg, RefName: ref}
	if len(rows) > pageSize {
		rows = rows[:pageSize]
		data.NextURL = logURL(pageNum + 1)
	}
	if pageNum > 1 {
		data.PrevURL = logURL(pageNum - 1)
	}
	data.Commits = rows
	s.render(w, http.StatusOK, "log", data)
}

// --- tree ---

type crumb struct {
	Name, URL string
}

type treeEntry struct {
	Mode, Type, Name, URL, Size string
}

type blobLine struct {
	Num  int
	Text string
}

type treeData struct {
	page
	RefName     string
	Path        string
	Crumbs      []crumb
	Entries     []treeEntry
	IsBlob      bool
	Binary      bool
	BlobSize    int64
	Lines       []blobLine
	Markdown    template.HTML
	SourceURL   string // markdown blob: line view (?source=1)
	RenderedURL string // markdown blob source view: back to rendered
	RawFileURL  string // any blob: raw endpoint
}

// cleanTreePath normalizes ?path= and rejects traversal. Returns the cleaned
// relative path ("" for the root) and ok.
func cleanTreePath(raw string) (string, bool) {
	if raw == "" {
		return "", true
	}
	cleaned := path.Clean(raw)
	if cleaned == "." {
		return "", true
	}
	if strings.HasPrefix(cleaned, "/") || cleaned == ".." || strings.HasPrefix(cleaned, "../") {
		return "", false
	}
	return cleaned, true
}

func (s *Server) handleTree(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), requestTimeout)
	defer cancel()
	repo, ok := s.resolveRepo(w, r)
	if !ok {
		return
	}
	pg := s.repoPage(repo, "tree")
	ref, ok := s.resolveRef(ctx, w, r, repo, pg)
	if !ok {
		return
	}
	treePath, ok := cleanTreePath(r.URL.Query().Get("path"))
	if !ok {
		s.notFound(w, pg, "Invalid path.")
		return
	}

	refParam := url.Values{}
	if r.URL.Query().Get("ref") != "" {
		refParam.Set("ref", ref)
	}
	treeURL := func(p string) string {
		q := url.Values{}
		for k, v := range refParam {
			q[k] = v
		}
		if p != "" {
			q.Set("path", p)
		}
		return repoURL(repo.Owner, repo.Name, "tree", q)
	}

	data := treeData{page: pg, RefName: ref, Path: treePath}
	data.Crumbs = append(data.Crumbs, crumb{Name: repo.Name, URL: treeURL("")})
	if treePath != "" {
		segments := strings.Split(treePath, "/")
		for i := range segments {
			data.Crumbs = append(data.Crumbs, crumb{
				Name: segments[i],
				URL:  treeURL(strings.Join(segments[:i+1], "/")),
			})
		}
	}

	listPath := "" // ls-tree path argument for directory listings
	if treePath != "" {
		out, err := s.git.Run(ctx, repo.GitDir, "ls-tree", "-l", "-z", ref, "--", treePath)
		if err != nil {
			s.fail(w, r, pg, err)
			return
		}
		probe := parseLsTree(out)
		if len(probe) == 0 {
			s.notFound(w, pg, fmt.Sprintf("Path %q not found at %s.", treePath, ref))
			return
		}
		entry := probe[0]
		if entry.Type == "blob" {
			s.renderBlob(ctx, w, r, repo, ref, treePath, entry, data)
			return
		}
		if entry.Type != "tree" {
			s.notFound(w, pg, fmt.Sprintf("Path %q is not browsable.", treePath))
			return
		}
		listPath = treePath + "/"
	}

	args := []string{"ls-tree", "-l", "-z", ref}
	if listPath != "" {
		args = append(args, "--", listPath)
	}
	out, err := s.git.Run(ctx, repo.GitDir, args...)
	if err != nil {
		s.fail(w, r, pg, err)
		return
	}
	for _, e := range parseLsTree(out) {
		name := strings.TrimPrefix(e.Name, treePath+"/")
		if treePath == "" {
			name = e.Name
		}
		row := treeEntry{Mode: e.Mode, Type: e.Type, Name: name, Size: "-"}
		if e.Type == "blob" {
			if n, err := strconv.ParseInt(e.Size, 10, 64); err == nil {
				row.Size = bytesize(n)
			}
		}
		if e.Type == "blob" || e.Type == "tree" {
			row.URL = treeURL(e.Name)
		}
		data.Entries = append(data.Entries, row)
	}
	s.render(w, http.StatusOK, "tree", data)
}

func (s *Server) renderBlob(ctx context.Context, w http.ResponseWriter, r *http.Request, repo backup.Repo, ref, treePath string, entry lsEntry, data treeData) {
	data.IsBlob = true
	refParam := url.Values{}
	if r.URL.Query().Get("ref") != "" {
		refParam.Set("ref", ref)
	}
	blobQuery := func() url.Values {
		q := url.Values{}
		for k, v := range refParam {
			q[k] = v
		}
		q.Set("path", treePath)
		return q
	}
	data.RawFileURL = repoURL(repo.Owner, repo.Name, "raw", blobQuery())
	size, _ := strconv.ParseInt(entry.Size, 10, 64)
	data.BlobSize = size
	if size > maxBlobRender {
		data.Binary = true
		s.render(w, http.StatusOK, "tree", data)
		return
	}
	out, err := s.git.Run(ctx, repo.GitDir, "cat-file", "blob", ref+":"+treePath)
	if err != nil {
		s.fail(w, r, data.page, err)
		return
	}
	head := out
	if len(head) > 8000 {
		head = head[:8000]
	}
	if bytes.IndexByte(head, 0) >= 0 {
		data.Binary = true
		s.render(w, http.StatusOK, "tree", data)
		return
	}
	if ext := strings.ToLower(path.Ext(treePath)); ext == ".md" || ext == ".markdown" {
		if r.URL.Query().Get("source") == "1" {
			data.RenderedURL = repoURL(repo.Owner, repo.Name, "tree", blobQuery()) // fall through to the line view
		} else {
			dir := path.Dir(treePath)
			if dir == "." {
				dir = ""
			}
			q := blobQuery()
			q.Set("source", "1")
			data.SourceURL = repoURL(repo.Owner, repo.Name, "tree", q)
			data.Markdown = markdownHTML(out, mdResolver{
				owner: repo.Owner, repo: repo.Name, refParam: refParam, dir: dir,
			})
			s.render(w, http.StatusOK, "tree", data)
			return
		}
	}
	text := strings.TrimSuffix(string(out), "\n")
	if text != "" {
		for i, line := range strings.Split(text, "\n") {
			data.Lines = append(data.Lines, blobLine{Num: i + 1, Text: line})
		}
	}
	s.render(w, http.StatusOK, "tree", data)
}

// handleRaw serves blob bytes directly. Sniffed text is always served as
// text/plain (never text/html) and every response carries nosniff, so
// backed-up repo content cannot become scriptable on this origin; images
// keep their sniffed type so direct viewing works.
func (s *Server) handleRaw(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), requestTimeout)
	defer cancel()
	repo, ok := s.resolveRepo(w, r)
	if !ok {
		return
	}
	pg := s.repoPage(repo, "tree")
	ref, ok := s.resolveRef(ctx, w, r, repo, pg)
	if !ok {
		return
	}
	treePath, ok := cleanTreePath(r.URL.Query().Get("path"))
	if !ok || treePath == "" {
		s.notFound(w, pg, "Invalid path.")
		return
	}
	out, err := s.git.Run(ctx, repo.GitDir, "cat-file", "blob", ref+":"+treePath)
	if err != nil {
		s.notFound(w, pg, fmt.Sprintf("File %q not found at %s.", treePath, ref))
		return
	}
	ct := http.DetectContentType(out)
	switch {
	case strings.HasPrefix(ct, "image/"):
		// Keep the sniffed image type.
	case strings.HasPrefix(ct, "text/"):
		ct = "text/plain; charset=utf-8"
	default:
		ct = "application/octet-stream"
	}
	w.Header().Set("Content-Type", ct)
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Write(out)
}

// --- commit ---

type diffLine struct {
	Class, Text string
}

type commitData struct {
	page
	Hash       string
	Parents    []commitRow
	Author     string
	AuthorTime int64
	Committer  string
	CommitTime int64
	Message    string
	TreeURL    string
	GitHubURL  string
	Stat       string
	Diff       []diffLine
	Truncated  bool
}

const commitFormat = "%H%x00%P%x00%an <%ae>%x00%at%x00%cn <%ce>%x00%ct%x00%B"

func (s *Server) handleCommit(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), requestTimeout)
	defer cancel()
	repo, ok := s.resolveRepo(w, r)
	if !ok {
		return
	}
	pg := s.repoPage(repo, "")
	id := r.URL.Query().Get("id")
	if id == "" {
		s.notFound(w, pg, "Missing commit id.")
		return
	}
	resolved, err := s.git.Run(ctx, repo.GitDir, "rev-parse", "--verify", "--quiet", "--end-of-options", id+"^{commit}")
	if err != nil {
		s.notFound(w, pg, fmt.Sprintf("Unknown commit %q.", id))
		return
	}
	sha := strings.TrimSpace(string(resolved))

	header, err := s.git.Run(ctx, repo.GitDir, "show", "--no-patch", "--format="+commitFormat, sha)
	if err != nil {
		s.fail(w, r, pg, err)
		return
	}
	fields := bytes.SplitN(header, nulSep, 7)
	if len(fields) < 7 {
		s.fail(w, r, pg, fmt.Errorf("unexpected commit header format for %s", sha))
		return
	}
	atime, _ := strconv.ParseInt(string(fields[3]), 10, 64)
	ctime, _ := strconv.ParseInt(string(fields[5]), 10, 64)

	data := commitData{
		page:       pg,
		Hash:       string(fields[0]),
		Author:     string(fields[2]),
		AuthorTime: atime,
		Committer:  string(fields[4]),
		CommitTime: ctime,
		Message:    strings.TrimSpace(string(fields[6])),
		TreeURL:    repoURL(repo.Owner, repo.Name, "tree", url.Values{"ref": {sha}}),
		GitHubURL:  "https://github.com/" + url.PathEscape(repo.Owner) + "/" + url.PathEscape(repo.Name) + "/commit/" + sha,
	}
	data.Title = repo.FullName() + " · " + data.Hash[:12]
	for _, p := range strings.Fields(string(fields[1])) {
		data.Parents = append(data.Parents, commitRow{
			Abbrev:    p[:min(12, len(p))],
			CommitURL: repoURL(repo.Owner, repo.Name, "commit", url.Values{"id": {p}}),
		})
	}

	diff, err := s.git.Run(ctx, repo.GitDir, "show", "--no-color", "--stat=120", "--patch", "--format=", sha)
	if errors.Is(err, gitcmd.ErrTruncated) {
		data.Truncated = true
	} else if err != nil {
		s.fail(w, r, pg, err)
		return
	} else {
		stat, patch := splitStatPatch(string(diff))
		data.Stat = stat
		data.Diff = classifyDiff(patch)
	}
	s.render(w, http.StatusOK, "commit", data)
}

// splitStatPatch splits `show --stat --patch` output at the first
// "diff --git" line.
func splitStatPatch(out string) (stat, patch string) {
	if strings.HasPrefix(out, "diff --git ") {
		return "", out
	}
	if i := strings.Index(out, "\ndiff --git "); i >= 0 {
		return strings.TrimRight(out[:i], "\n"), out[i+1:]
	}
	return strings.TrimRight(out, "\n"), ""
}

func classifyDiff(patch string) []diffLine {
	if patch == "" {
		return nil
	}
	lines := strings.Split(strings.TrimSuffix(patch, "\n"), "\n")
	out := make([]diffLine, 0, len(lines))
	for _, l := range lines {
		var class string
		switch {
		case strings.HasPrefix(l, "diff --git "),
			strings.HasPrefix(l, "index "),
			strings.HasPrefix(l, "--- "),
			strings.HasPrefix(l, "+++ "),
			strings.HasPrefix(l, "new file"),
			strings.HasPrefix(l, "deleted file"),
			strings.HasPrefix(l, "similarity "),
			strings.HasPrefix(l, "rename "),
			strings.HasPrefix(l, "Binary files "):
			class = "text-zinc-500"
		case strings.HasPrefix(l, "@@"):
			class = "text-blue-300"
		case strings.HasPrefix(l, "+"):
			class = "text-emerald-300"
		case strings.HasPrefix(l, "-"):
			class = "text-rose-300"
		default:
			class = "text-zinc-300"
		}
		out = append(out, diffLine{Class: class, Text: l})
	}
	return out
}
