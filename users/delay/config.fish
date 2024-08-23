set fish_greeting # Disable greeting message.
set -g fish_term24bit 1 # Enable true color support.

fish_vi_key_bindings # Enable vi bindings.

function fish_prompt
  set_color --bold blue
  printf "_ "
  set_color normal
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

function fish_right_prompt
  printf " "
  set_color black
  printf ""
  set_color normal; set_color grey --background black
  printf " %s " (date '+%H:%M:%S')
  set_color normal; set_color black
  printf ""
  set_color normal

  set -l citc_space (citc_get_space_name)
  if test -n "$citc_space"
    set_color magenta --reverse
    printf "   %s " $citc_space
    set_color normal
    set_color magenta
  else
    set -l nix_shell (nix_shell_get_name)
    if test -n "$nix_shell"
      set_color blue --reverse
      printf " 󱄅  %s " $nix_shell
      set_color normal
      set_color blue
    else
      set -l git_repo (git_repo_get_name)
      if test -n "$git_repo"
        set_color red --reverse
        printf " 󰊢  %s " $git_repo
        set_color normal
        set_color red
      else
        set_color green --reverse
        printf " 󰉋  %s " (path basename $PWD)
        set_color normal
        set_color green
      end
    end
  end
  printf ""
  set_color normal
end
