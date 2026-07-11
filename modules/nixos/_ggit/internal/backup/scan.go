// Package backup discovers owners and repositories inside a
// python-github-backup output tree and enriches them with descriptions.
package backup

import (
	"encoding/json"
	"errors"
	"io/fs"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/BurntSushi/toml"
)

// Repo is one discovered repository.
type Repo struct {
	Owner       string
	Name        string
	GitDir      string // absolute path to the git directory
	Description string
}

// FullName returns "owner/name".
func (r Repo) FullName() string { return r.Owner + "/" + r.Name }

// Owner groups the repositories of one backed-up account.
type Owner struct {
	Name  string
	Repos []Repo
}

type ggitConfig struct {
	Descriptions map[string]string `toml:"descriptions"`
}

// Scan walks root and returns the owners (sorted case-insensitively), each
// with its repositories (also sorted). Descriptions come from, in decreasing
// precedence: <root>/ggit.toml, <owner>/account/watched.json,
// <owner>/account/starred.json. All enrichment is best-effort.
func Scan(root string) ([]Owner, error) {
	entries, err := os.ReadDir(root)
	if err != nil {
		return nil, err
	}

	descriptions := map[string]string{}
	// Lowest precedence first: later merges overwrite.
	for _, o := range entries {
		if !o.IsDir() {
			continue
		}
		mergeAccountJSON(descriptions, filepath.Join(root, o.Name(), "account", "starred.json"))
	}
	for _, o := range entries {
		if !o.IsDir() {
			continue
		}
		mergeAccountJSON(descriptions, filepath.Join(root, o.Name(), "account", "watched.json"))
	}
	mergeGgitTOML(descriptions, filepath.Join(root, "ggit.toml"))

	var owners []Owner
	for _, o := range entries {
		if !o.IsDir() {
			continue
		}
		reposDir := filepath.Join(root, o.Name(), "repositories")
		repoEntries, err := os.ReadDir(reposDir)
		if err != nil {
			continue // not an owner directory
		}
		owner := Owner{Name: o.Name()}
		for _, r := range repoEntries {
			if !r.IsDir() {
				continue
			}
			gitDir, ok := resolveGitDir(filepath.Join(reposDir, r.Name(), "repository"))
			if !ok {
				continue
			}
			repo := Repo{Owner: o.Name(), Name: r.Name(), GitDir: gitDir}
			repo.Description = descriptions[repo.FullName()]
			owner.Repos = append(owner.Repos, repo)
		}
		if len(owner.Repos) == 0 {
			continue
		}
		sort.Slice(owner.Repos, func(i, j int) bool {
			return strings.ToLower(owner.Repos[i].Name) < strings.ToLower(owner.Repos[j].Name)
		})
		owners = append(owners, owner)
	}
	sort.Slice(owners, func(i, j int) bool {
		return strings.ToLower(owners[i].Name) < strings.ToLower(owners[j].Name)
	})
	return owners, nil
}

// resolveGitDir returns the usable git directory for a backup repository
// path: <path>/.git if it exists (non-bare fallback), else <path> itself.
// Directories without a HEAD file are skipped.
func resolveGitDir(path string) (string, bool) {
	candidates := []string{filepath.Join(path, ".git"), path}
	for _, dir := range candidates {
		if info, err := os.Stat(dir); err != nil || !info.IsDir() {
			continue
		}
		if _, err := os.Stat(filepath.Join(dir, "HEAD")); err == nil {
			return dir, true
		}
	}
	return "", false
}

// mergeAccountJSON merges full_name→description pairs from a GitHub
// repository-array JSON file (watched.json/starred.json). Missing files and
// parse errors are silent (best-effort by design).
func mergeAccountJSON(dst map[string]string, path string) {
	data, err := os.ReadFile(path)
	if err != nil {
		return
	}
	var repos []struct {
		FullName    string  `json:"full_name"`
		Description *string `json:"description"`
	}
	if err := json.Unmarshal(data, &repos); err != nil {
		return
	}
	for _, r := range repos {
		if r.FullName == "" || r.Description == nil {
			continue
		}
		dst[r.FullName] = *r.Description
	}
}

// mergeGgitTOML merges the handwritten [descriptions] table from ggit.toml.
// A missing file is silent; a parse error is logged and skipped so pages
// still render from the other sources.
func mergeGgitTOML(dst map[string]string, path string) {
	var cfg ggitConfig
	if _, err := toml.DecodeFile(path, &cfg); err != nil {
		if !errors.Is(err, fs.ErrNotExist) {
			log.Printf("ERROR reading %s: %v", path, err)
		}
		return
	}
	for k, v := range cfg.Descriptions {
		dst[k] = v
	}
}
