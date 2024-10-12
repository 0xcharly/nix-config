function __hash_path -d 'Returns a hashed string representation of the input path'
  # Returns a stable string in the following format: "<hash>-<basename>".
  set -l path $argv[1]

  #echo -n (nix-hash --type sha1 --to-base32 (echo $path |sha1sum |awk '{print $1}'))
  # TODO: Switch to `nix hash convert` after 24.11 (Nix 2.18.2 does not have the
  # command, but 2.21.2 does).
  echo -n (nix hash convert --hash-algo sha1 --to nix32 (echo $path |sha1sum |awk '{print $1}') |cut -c -8)
  echo -n "-"
  basename -z $path
end

set -l gitget_root (eval realpath (git config gitget.root))

if ! test -d "$gitget_root"
  echo "git-get root directory missing or not configured" >&2
  return 1
end

set -q OPEN_GIT_REPOSITORY_COMMAND
or set -l OPEN_GIT_REPOSITORY_COMMAND "
  command find $gitget_root -type d -name .git -exec dirname {} \; \
  | command xargs realpath \
  | string replace \"$gitget_root/\" \"\" \
  | command fzf +m --bind=ctrl-r:toggle-sort --highlight-line"

eval "$OPEN_GIT_REPOSITORY_COMMAND" | read -l repository

if test -z "$repository"
  return 0
end

set -l session_name (__hash_path $repository)
set -l session_cwd "$gitget_root/$repository"

if test "$ZELLIJ_SESSION_NAME" = "$session_name"
  return 0
end

command zellij --config /Users/delay/code/github.com/0xcharly/nix-config/parts/pkgs/packages/zellij-switch-repository/dev.kdl \
    attach --create-background $session_name \
    options --default-cwd $session_cwd 2> /dev/null

if test -z $ZELLIJ
  command zellij --config /Users/delay/code/github.com/0xcharly/nix-config/parts/pkgs/packages/zellij-switch-repository/dev.kdl attach $session_name
else
  # TODO: consider using a common API, e.g. with:
  #   zellij action launch-or-focus-plugin --configuration "some_key=some_value,another_key=1"
  command zellij --config /Users/delay/code/github.com/0xcharly/nix-config/parts/pkgs/packages/zellij-switch-repository/dev.kdl \
      pipe --plugin "file:/Users/delay/code/github.com/0xcharly/nix-config/parts/pkgs/packages/zellij-switch-repository/target/wasm32-wasip1/release/zellij-switch-session.wasm" -- "SwitchSession $session_name $session_cwd"
end

return $status
