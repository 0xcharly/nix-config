#! /usr/bin/env bash

set -o nounset
set -o pipefail

# The pre-wipe ritual: run ON the target host before any wipe. Prints a
# findings report; exits 1 if anything was found that deserves a look.
#
# /tmp-level leftovers are skipped deliberately — ephemeral by definition.

findings=0

report() {
  findings=1
  echo -e "\033[33;1mFOUND\033[0m: $1"
}

log_info() {
  echo -e "\033[32;1mINFO\033[0m: $1"
}

# --- Dirty or unpushed VCS repos under ~/code -------------------------------
log_info "Scanning ~/code for dirty or unpushed repositories…"
if test -d "$HOME/code"; then
  while IFS= read -r -d '' marker; do
    repo=$(dirname "$marker")
    case "$marker" in
    *.jj)
      # jj repo (possibly colocated): git commands fail on non-colocated jj
      # repos, so use jj for both checks. The dirty probe MUST snapshot the
      # working copy (no --ignore-working-copy): edits made since the last
      # jj invocation must count as dirty, or they die with the wipe. Ask
      # the template engine, not the human-readable output — its phrasing
      # varies across jj versions.
      dirty=$(cd "$repo" && jj log --no-graph -r '@' -T 'if(empty, "", "dirty")' 2>/dev/null)
      if test "$dirty" = "dirty"; then
        report "$repo: dirty working copy (jj)"
      fi
      # `remote_bookmarks()..` alone ALWAYS matches: the working-copy commit
      # itself is never pushed. Empty commits (the idle working copy,
      # undescribed heads) carry no content — only non-empty unpushed
      # revisions are findings.
      unpushed=$(cd "$repo" && jj --ignore-working-copy log --no-graph -r 'remote_bookmarks().. ~ empty()' -T 'commit_id ++ "\n"' 2>/dev/null)
      if test -n "$unpushed"; then
        report "$repo: unpushed revisions (jj log -r 'remote_bookmarks().. ~ empty()')"
      fi
      ;;
    *.git)
      # Plain git repo (jj-colocated repos are handled above and skipped here).
      if test -e "$repo/.jj"; then
        continue
      fi
      if test -n "$(cd "$repo" && git status --porcelain 2>/dev/null)"; then
        report "$repo: dirty working copy (git status)"
      fi
      if test -n "$(cd "$repo" && git log --branches --not --remotes --oneline 2>/dev/null)"; then
        report "$repo: unpushed commits (git log --branches --not --remotes)"
      fi
      ;;
    esac
  done < <(find "$HOME/code" -maxdepth 4 \( -name .jj -o -name .git \) -print0 2>/dev/null)
else
  log_info "No ~/code directory."
fi

# --- Non-empty user directories ---------------------------------------------
for dir in Downloads Documents Desktop; do
  path="$HOME/$dir"
  if test -d "$path" && test -n "$(ls -A "$path" 2>/dev/null)"; then
    report "~/$dir is not empty:"
    ls -A "$path"
  fi
done

# --- OMP sessions -------------------------------------------------------------
if test -d "$HOME/.omp"; then
  report "~/.omp present — back up OMP sessions (~/.omp/agent/{sessions,agent.db,history.db,blobs,terminal-sessions})."
fi

# --- State directories: eyeball against the persist allowlist -----------------
log_info "Top-level /var/lib, /srv, /root entries — eyeball against this host's persist allowlist:"
for dir in /var/lib /srv /root; do
  echo "--- $dir:"
  sudo ls -A "$dir" 2>/dev/null || ls -A "$dir" 2>/dev/null || echo "(unreadable)"
done

echo
if test "$findings" -ne 0; then
  echo -e "\033[33;1mFindings above\033[0m — resolve before wiping."
  exit 1
fi

log_info "No findings. Clear to proceed (after eyeballing the state dirs above)."
exit 0
