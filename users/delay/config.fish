set fish_greeting # Disable greeting message.
set -g fish_term24bit 1 # Enable true color support.

fish_vi_key_bindings # Enable vi bindings.

function fish_prompt
  # Print the prompt.
  set_color --bold blue
  printf "_ "
  set_color normal
end

function transient_prompt_func
  set_color --bold brgrey
  printf ">: "
  set_color normal

  # Reset vi mode to insert.
  set fish_bind_mode insert
  commandline -f repaint-mode
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

function segment -a icon text segment_fg segment_bg
  set -l fg "d0d1d7"
  set -l bg "313239"
  printf " "
  set_color normal; set_color $segment_bg
  printf ""
  set_color $segment_fg --background $segment_bg
  printf $icon
  set_color normal; set_color $segment_bg
  printf ""
  set_color normal; set_color $bg --reverse
  printf ""
  set_color normal; set_color $fg --background $bg
  printf " %s" $text
  set_color normal; set_color $bg
  printf ""
  set_color normal
end

function fish_right_prompt
  # The transient.fish plugin overwrites $status and $pipestatus, but saves them
  # in $transient_status and $transient_pipestatus, respectively.
  set -l _status $transient_pipestatus[-1]
  if test -z "$_status" || test "$_status" -ne 0
    segment "󱖫 " $_status "fe9fa9" "41262e" # Red
  end

  set -l citc_space (citc_get_space_name)
  if test -n "$citc_space"
    segment " " $citc_space "cab4f4" "312b41" # Purple
  else
    set -l nix_shell (nix_shell_get_name)
    if test -n "$nix_shell"
      segment "󱄅 " $nix_shell "9fcdfe" "203147" # Blue
    else
      set -l git_repo (git_repo_get_name)
      if test -n "$git_repo"
        segment "󰊢 " $git_repo "fec49a" "433027" # Orange
      else
        segment "󰉋 " (path basename $PWD) "aff3c0" "243c2e" # Green
      end
    end
  end
end
