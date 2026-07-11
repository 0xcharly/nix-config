// Command ggit serves a read-only, dark-mode HTML view of a
// python-github-backup output tree.
package main

import (
	"flag"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"strconv"

	"github.com/0xcharly/nix-config/ggit/internal/backup"
	"github.com/0xcharly/nix-config/ggit/internal/gitcmd"
	"github.com/0xcharly/nix-config/ggit/internal/web"
)

func main() {
	listen := flag.String("listen", "localhost", "bind address")
	port := flag.Int("port", 9917, "listen port")
	gitBin := flag.String("git", "git", "path to the git binary")
	flag.Usage = func() {
		fmt.Fprintf(flag.CommandLine.Output(), "usage: %s [flags] <backup-root>\n", os.Args[0])
		flag.PrintDefaults()
	}
	flag.Parse()

	if flag.NArg() != 1 {
		flag.Usage()
		os.Exit(2)
	}
	root := flag.Arg(0)
	if info, err := os.Stat(root); err != nil || !info.IsDir() {
		fmt.Fprintf(os.Stderr, "ggit: backup root %q is not a directory\n", root)
		flag.Usage()
		os.Exit(2)
	}
	resolvedGit, err := exec.LookPath(*gitBin)
	if err != nil {
		fmt.Fprintf(os.Stderr, "ggit: git binary %q not found: %v\n", *gitBin, err)
		os.Exit(2)
	}

	owners, err := backup.Scan(root)
	if err != nil {
		log.Fatalf("ggit: scanning %s: %v", root, err)
	}
	repoCount := 0
	for _, o := range owners {
		repoCount += len(o.Repos)
	}

	srv := web.NewServer(root, gitcmd.Git{Bin: resolvedGit})
	addr := net.JoinHostPort(*listen, strconv.Itoa(*port))
	log.Printf("ggit listening on %s, root=%s git=%s (%d owners, %d repositories)",
		addr, root, resolvedGit, len(owners), repoCount)
	server := &http.Server{Addr: addr, Handler: srv.Handler()}
	log.Fatal(server.ListenAndServe())
}
