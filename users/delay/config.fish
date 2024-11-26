set fish_greeting # Disable greeting message.
set -g fish_term24bit 1 # Enable true color support.

fish_vi_key_bindings # Enable vi bindings.

function fish_prompt
  # Print the prompt.
  set_color --bold blue
  printf "_ "
  set_color normal

  # Reset vi mode to insert.
  set fish_bind_mode insert
  commandline -f repaint-mode
end

function transient_prompt_func
  set_color --bold brgrey
  printf ">: "
  set_color normal
end

# TODO: move this to corp-machines only.
function citc_get_space_name
  set -l pwd (pwd)
  set -l whoami (whoami)
  string match -rq "/google/src/cloud/$whoami/(?<citc_space>[a-zA-Z0-9_-]+)/google3" (pwd)
  if test -n "$citc_space"
    printf "$citc_space"
  end
end

function nix_shell_get_name
  if test -n "$IN_NIX_SHELL"
      path basename $PWD
  end
end

function git_repo_get_name
  set -l git_dir (git rev-parse --show-toplevel 2> /dev/null)
  if test -n "$git_dir"
    path basename $git_dir
  end
end

function segment -a icon text color
  printf " "
  set_color normal; set_color $color
  printf ""
  set_color $color --reverse
  printf $icon
  set_color normal; set_color $color
  printf ""
  set_color normal; set_color black --reverse
  printf ""
  set_color normal; set_color grey --background black
  printf " %s" $text
  set_color normal; set_color black
  printf ""
  set_color normal
end

function fish_right_prompt
  # TODO: this doesn't work for some reason: $status is always 0…
  set -l _status $status
  if test $_status -ne 0
    segment "󱖫 " $_status red
  end

  set -l citc_space (citc_get_space_name)
  if test -n "$citc_space"
    segment " " $citc_space "cba6f7" # Mauve
  else
    set -l nix_shell (nix_shell_get_name)
    if test -n "$nix_shell"
      segment "󱄅 " $nix_shell "74c7ec" # Sapphire
    else
      set -l git_repo (git_repo_get_name)
      if test -n "$git_repo"
        segment "󰊢 " $git_repo "eba0ac" # Maroon
      else
        segment "󰉋 " (path basename $PWD) "94e2d5" # Teal
      end
    end
  end
end
