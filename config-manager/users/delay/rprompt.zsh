# Returns the name of the current CitC workspace, or nothing otherwise.
# TODO: move this to corp-machines only.
__delay_citc_workspace_match_re="/google/src/cloud/$(whoami)/([a-zA-Z0-9_-]+)/google3"
__delay_rprompt_citc_workspace() {
  if [[ $PWD =~ $__delay_citc_workspace_match_re ]]; then
    echo -n ${BASH_REMATCH[2]}
  fi
}

# Returns the name of the current nix-shell, or nothing otherwise.
__delay_rprompt_nix_shell() {
  if [ -n "$IN_NIX_SHELL" ]; then
    echo -n $(basename $PWD)
  fi
}

# Returns the name of the current Git repository, or nothing otherwise.
__delay_rprompt_git_repo() {
  git_dir=$(git rev-parse --show-toplevel 2> /dev/null)
  if [ -n "$git_dir" ]; then
    echo -n $(basename $git_dir)
  fi
}

# Creates the right prompt based on the current working directory.
__delay_rprompt() {
  # First segment: time.
  echo -n " %F{black}%F{grey}%K{black} %* %k%F{black}"

  # Second segment: working directory or space.
  {
    # CitC space.
    citc_workspace=$(__delay_rprompt_citc_workspace)
    if [ -n "$citc_workspace" ]; then
      echo -en "%F{magenta}%{\e[7m%}   $citc_workspace %{\e[0m%}%F{magenta}"
      return
    fi

    # Nix-shell (e.g. via direnv).
    nix_shell=$(__delay_rprompt_nix_shell)
    if [ -n "$nix_shell" ]; then
      echo -en "%F{blue}%{\e[7m%}   $nix_shell %{\e[0m%}%F{blue}"
      return
    fi

    # Git repository. Defer that check to as late as possible to avoid paying
    # the price of a call to `git` when unnecessary (e.g. in a CitC workspace).
    git_repo=$(__delay_rprompt_git_repo)
    if [ -n "$git_repo" ]; then
      echo -en "%F{red}%{\e[7m%}   $git_repo %{\e[0m%}%F{red}"
      return
    fi

    # Defaults to the current working directory.
    echo -en "%F{green}%{\e[7m%} 󰉋  %1d %{\e[0m%}%F{green}"
  } always {
    # Close segment.
    echo -n "%k%f%k%{\e[0m%}"
  }
}

setopt bash_rematch prompt_subst transient_rprompt
precmd_prompt () {
  RPROMPT="$(__delay_rprompt)"
}
precmd_functions+=(precmd_prompt)
