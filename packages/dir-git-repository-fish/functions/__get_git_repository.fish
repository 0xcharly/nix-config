function __get_git_repository -d 'List local repositories organized following `git-get` organisation'
  if status --is-interactive
    set -l query (commandline)
  end
  set -l gitget_root (eval realpath (git config gitget.root))

  if ! test -d "$gitget_root"
    echo "git-get root directory missing or not configured" >&2
    return 1
  end

  set -q OPEN_GIT_REPOSITORY_COMMAND
  or set -l OPEN_GIT_REPOSITORY_COMMAND "
      command find $gitget_root -depth -maxdepth 4 -type d -name .git -prune -exec dirname {} \; \
    | command xargs realpath \
    | string replace \"$gitget_root/\" \"\""

  set -l fzf_opts "$FZF_DEFAULT_OPTS +m --reverse --bind=ctrl-r:toggle-sort --highlight-line \$FZF_CTRL_R_OPTS --query=\"\$query\""
  eval "$OPEN_GIT_REPOSITORY_COMMAND | command fzf $fzf_opts" | read -l repository

  if test -z "$repository"
    if status --is-interactive
      commandline -f repaint
    end
    return 1
  end

  if status --is-interactive
    commandline -f kill-whole-line repaint
  end

  echo "$gitget_root/$repository"
  return 0
end
