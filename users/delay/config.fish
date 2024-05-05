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
    set_color brgrey
    string repeat --count $SHLVL --no-newline ":"
    printf " "
    set_color normal
end

function fish_right_prompt
    set_color brgrey
    printf " %s " (date '+%H:%M:%S')
    print_pwd
    set_color normal
end

function print_pwd
    set -l pwd (pwd)
    # TODO: move this to corp-machines only.
    set -l whoami (whoami)
    string match -rq "/google/src/cloud/$whoami/(?<citc_space>[a-zA-Z0-9_-]+)/google3" (pwd)
    if test -n "$citc_space"
        set_color blue
        printf "<$citc_space>"
    else if set -q VIRTUAL_ENV
        set_color magenta
        printf "<%s>" (basename $VIRTUAL_ENV)
    else
        set -l pwd_segment_bg_color green
        fish_is_root_user; and set pwd_segment_bg_color red
        set_color $pwd_segment_bg_color
        printf "<%s> " (path basename $PWD)
    end
end
