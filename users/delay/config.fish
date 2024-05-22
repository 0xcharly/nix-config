set fish_greeting # Disable greeting message.
set -g fish_term24bit 1 # Enable true color support.

fish_vi_key_bindings # Enable vi bindings.

test -d $HOME/.cargo/bin && fish_add_path $HOME/.cargo/bin
test -d $HOME/.local/bin && fish_add_path $HOME/.local/bin
test -x /opt/homebrew/bin/brew && eval (/opt/homebrew/bin/brew shellenv)

string match -q -- "*.c.googlers.com" (hostname) && alias bat batcat

# Catppuccin theme for FzF. https://github.com/catppuccin/fzf
set -e FZF_DEFAULT_OPTS
set -Ux FZF_DEFAULT_OPTS "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc,marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"

bind \cf ~/.local/bin/open-tmux-workspace
bind -M insert \cf ~/.local/bin/open-tmux-workspace

function fish_mode_prompt -d "Disable prompt vi mode reporting"
end

function fish_prompt
  set_color --bold brgrey
  string repeat --count $SHLVL --no-newline ":"
  printf " "
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
  set -l git_dir (git rev-parse --show-toplevel)
  if test -n "$git_dir"
    path basename $git_dir
  end
end

function fish_right_prompt
  set -l citc_space (citc_get_space_name)
  set -l nix_shell (nix_shell_get_name)
  set -l git_repo (git_repo_get_name)

  set_color brgrey
  printf ""
  set_color normal; set_color --background brgrey --bold
  printf " %s " (date '+%H:%M:%S')
  set_color normal; set_color brgrey
  printf ""
  set_color normal
  if test -n "$citc_space"
    set_color magenta --reverse --bold
    printf "   %s " $citc_space
  else if test -n "$nix_shell"
    set_color blue --reverse --bold
    printf " 󱄅  %s " $nix_shell
  else if test -n "$git_repo"
    set_color red --reverse --bold
    printf " 󰊢  %s " $git_repo
  else if test -n "$nix_shell"
    set_color blue --reverse --bold
    printf " 󱄅  %s " $nix_shell
  else
    set_color green --reverse --bold
    printf " 󰉋  %s " (path basename $PWD)
  end
  set_color normal
  if test -n "$citc_space"
    set_color magenta
  else if test -n "$nix_shell"
    set_color blue
  else if test -n "$git_repo"
    set_color red
  else
    set_color green
  end
  printf " "
  set_color normal
end
