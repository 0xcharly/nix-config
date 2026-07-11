// Package gitcmd wraps execution of the git binary against bare git
// directories. Every call shells out; there is no libgit2/go-git binding.
package gitcmd

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
)

// MaxOutput caps captured stdout of any single git invocation.
const MaxOutput = 8 << 20 // 8 MiB

// ErrTruncated is returned (wrapped in *GitError-free form) when git output
// exceeds MaxOutput.
var ErrTruncated = errors.New("git output truncated")

// GitError carries full diagnostics for a failed git invocation.
type GitError struct {
	Args     []string
	GitDir   string
	ExitCode int
	Stderr   string
}

func (e *GitError) Error() string {
	return fmt.Sprintf("git %v (git-dir %s, exit %d): %s", e.Args, e.GitDir, e.ExitCode, e.Stderr)
}

// Git executes the configured git binary.
type Git struct {
	Bin string
}

// Run executes git with --git-dir=gitDir and the given args, returning
// captured stdout. Output is forced stable and machine-parseable: color is
// disabled at config level (no gitconfig can re-enable it) and LC_ALL=C pins
// the locale. Stdout is capped at MaxOutput; exceeding the cap returns
// ErrTruncated. Non-zero exit returns a *GitError with the first 512 bytes of
// stderr.
func (g Git) Run(ctx context.Context, gitDir string, args ...string) ([]byte, error) {
	argv := append([]string{"-c", "color.ui=never", "--git-dir", gitDir}, args...)
	cmd := exec.CommandContext(ctx, g.Bin, argv...)
	cmd.Env = []string{"PATH=" + os.Getenv("PATH"), "LC_ALL=C"}

	var stderr bytes.Buffer
	cmd.Stderr = &stderr

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return nil, err
	}
	if err := cmd.Start(); err != nil {
		return nil, err
	}
	// Read one byte past the cap to detect truncation, then drain the rest so
	// git never blocks on a full pipe before Wait.
	out, readErr := io.ReadAll(io.LimitReader(stdout, MaxOutput+1))
	if len(out) > MaxOutput {
		_, _ = io.Copy(io.Discard, stdout)
	}
	waitErr := cmd.Wait()

	if readErr != nil {
		return nil, readErr
	}
	if waitErr != nil {
		errText := stderr.String()
		if len(errText) > 512 {
			errText = errText[:512]
		}
		exitCode := -1
		var exitErr *exec.ExitError
		if errors.As(waitErr, &exitErr) {
			exitCode = exitErr.ExitCode()
		}
		return nil, &GitError{Args: args, GitDir: gitDir, ExitCode: exitCode, Stderr: errText}
	}
	if len(out) > MaxOutput {
		return nil, ErrTruncated
	}
	return out, nil
}
