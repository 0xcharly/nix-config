function __open_local_repository -d 'List local repositories organized following `git-get` organisation'
  set -l query (commandline)
  set -l gitget_root (eval realpath (git config gitget.root))

  if ! test -d "$gitget_root"
    echo "git-get root directory missing or not configured" >&2
    return 1
  end

  set -q OPEN_GIT_REPOSITORY_COMMAND
  or set -l OPEN_GIT_REPOSITORY_COMMAND "
    command git list -o flat \
    | command ansifilter \
    | command rg '^/' --color=never \
    | command awk '{print \$1}' \
    | xargs realpath -s --relative-to \"\$gitget_root\" 2> /dev/null"

  set -l FZF_DEFAULT_OPTS (__fzf_defaults "" "+m --reverse --bind=ctrl-r:toggle-sort --highlight-line \$FZF_CTRL_R_OPTS --query=\"\$query\"")
  eval "$OPEN_GIT_REPOSITORY_COMMAND | " (__fzfcmd) "$FZF_DEFAULT_OPTS" | read -l repository

  if test -z "$repository"
    commandline -f repaint
    return 0
  end

  set -l sanitized_repository (echo $repository |tr . _)

  commandline -f kill-whole-line repaint

  # Check if the session exists already, or create it otherwise.
  if ! command tmux has-session -t "$sanitized_repository" 2>/dev/null
    # Create a detached session that we'll join below, creating the workspace if it doesn't exist.
    command tmux new-session -ds "$sanitized_repository" -c "$gitget_root/$repository"
  end

  if test -z "$TMUX"
    # If we're not running in a tmux client, attach to the session.
    command tmux attach-session -t "$sanitized_repository"
  else
    # If we're already running in a tmux client, just switch the client.
    command tmux switch-client -t "$sanitized_repository"
  end

  return $status
end
