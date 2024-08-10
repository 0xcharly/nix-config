# Adapted from the fzf ZSH integration.
# https://github.com/junegunn/fzf/blob/23a391e71599fadb780b53f716c86d5aec07e1d8/shell/completion.zsh
#
# Both branches of the following `if` do the same thing -- define
# __tmux_key_bindings_options such that `eval $__tmux_key_bindings_options` sets
# all options to the same values they currently have. We'll do just that at the
# bottom of the file after changing options to what we prefer.
#
# IMPORTANT: Until we get to the `emulate` line, all words that *can* be quoted
# *must* be quoted in order to prevent alias expansion. In addition, code must
# be written in a way works with any set of zsh options. This is very tricky, so
# careful when you change it.
#
# Start by loading the builtin zsh/parameter module. It provides `options`
# associative array that stores current shell options.
if 'zmodload' 'zsh/parameter' 2>'/dev/null' && (( ${+options} )); then
  # This is the fast branch and it gets taken on virtually all Zsh installations.
  #
  # ${(kv)options[@]} expands to array of keys (option names) and values ("on"
  # or "off"). The subsequent expansion# with (j: :) flag joins all elements
  # together separated by spaces. __tmux_key_bindings_options ends up with a
  # value like this: "options=(shwordsplit off aliases on ...)".
  __tmux_key_bindings_options="options=(${(j: :)${(kv)options[@]}})"
else
  # This branch is much slower because it forks to get the names of all
  # zsh options. It's possible to eliminate this fork but it's not worth the
  # trouble because this branch gets taken only on very ancient or broken
  # zsh installations.
  () {
    # That `()` above defines an anonymous function. This is essentially a scope
    # for local parameters. We use it to avoid polluting global scope.
    'local' '__fzf_opt'
    __tmux_key_bindings_options="setopt"
    # `set -o` prints one line for every zsh option. Each line contains option
    # name, some spaces, and then either "on" or "off". We just want option names.
    # Expansion with (@f) flag splits a string into lines. The outer expansion
    # removes spaces and everything that follow them on every line. __fzf_opt
    # ends up iterating over option names: shwordsplit, aliases, etc.
    for __fzf_opt in "${(@)${(@f)$(set -o)}%% *}"; do
      if [[ -o "$__fzf_opt" ]]; then
        # Option $__fzf_opt is currently on, so remember to set it back on.
        __tmux_key_bindings_options+=" -o $__fzf_opt"
      else
        # Option $__fzf_opt is currently off, so remember to set it back off.
        __tmux_key_bindings_options+=" +o $__fzf_opt"
      fi
    done
    # The value of __tmux_key_bindings_options here looks like this:
    # "setopt +o shwordsplit -o aliases ..."
  }
fi

# Enable the default zsh options (those marked with <Z> in `man zshoptions`)
# but without `aliases`. Aliases in functions are expanded when functions are
# defined, so if we disable aliases here, we'll be sure to have no pesky
# aliases in any of our functions. This way we won't need prefix every
# command with `command` or to quote every word to defend against global
# aliases. Note that `aliases` is not the only option that's important to
# control. There are several others that could wreck havoc if they are set
# to values we don't expect. With the following `emulate` command we
# sidestep this issue entirely.
'builtin' 'emulate' 'zsh' && 'builtin' 'setopt' 'no_aliases'

# This brace is the start of try-always block. The `always` part is like
# `finally` in lesser languages. We use it to *always* restore user options.
{
# The 'emulate' command should not be placed inside the interactive if check;
# placing it there fails to disable alias expansion.
# See https://github.com/junegunn/fzf/issues/3731.
if [[ -o interactive ]]; then

# Open git repositories.
tmux-open-git-repository() {
  setopt localoptions pipefail no_aliases 2> /dev/null

  # Don't reimplement the functions from the fzf integration, just reuse them.
  if ! whence -w __fzfcmd >/dev/null || ! whence -w __fzf_defaults >/dev/null; then
    >&2 echo "error: fzf ZSH integration not loaded"
    zle redisplay
    return 1
  fi

  # Use FZF to get user input.
  local gitget_root="$(eval realpath $(git config gitget.root))"
  local cmd="${TMUX_OPEN_GIT_REPOSITORY_COMMAND:-"command git list -o flat |awk '{print \$1}' |xargs realpath -s --relative-to \"$gitget_root\" 2> /dev/null"}"
  local repository="$(eval "$cmd" |
    FZF_DEFAULT_OPTS=$(__fzf_defaults "" "--reverse --bind=ctrl-r:toggle-sort --highlight-line ${FZF_CTRL_R_OPTS-} --query=${(qqq)LBUFFER} +m") \
    FZF_DEFAULT_OPTS_FILE='' $(__fzfcmd))"

  # Exit if the input is empty.
  if [ -z "$repository" ]; then
    zle redisplay
    return 0
  fi
  local sanitized_repository="$(echo $repository |tr . -)"

  # TODO: either fail if $repository is not in the input list, or support
  # cloning the repository on the fly.

  # Clear buffer.
  zle kill-buffer
  zle redisplay

  # Restore file descriptors redirected by ZLE. See `man zlezsh`.
  exec </dev/tty
  exec <&1

  # Check if the session exists already, or create it otherwise.
  if ! tmux has-session -t "$sanitized_repository" 2>/dev/null; then
    # Create a detached session that we'll join below.
    tmux new-session -ds "$sanitized_repository" -c "$gitget_root/$repository"
  fi

  if [ -z "${TMUX:-}" ]; then
    # If not running in a tmux client, attach to the session.
    tmux attach-session -t "$sanitized_repository"
  else
    # If already running in a tmux client, switch to the session.
    tmux switch-client -t "$sanitized_repository"
  fi

  local ret=$?

  # Ensure these don't end up appearing in prompt expansion.
  unset cmd
  unset gitget_roots
  unset repository
  unset sanitized_repository
  zle reset-prompt
  return $ret
}

zle     -N            tmux-open-git-repository
bindkey -M emacs '^F' tmux-open-git-repository
bindkey -M vicmd '^F' tmux-open-git-repository
bindkey -M viins '^F' tmux-open-git-repository

fi # [[ -o interactive ]]

} always {
  # Restore the original options.
  eval $__tmux_key_bindings_options
  'unset' '__tmux_key_bindings_options'
}
