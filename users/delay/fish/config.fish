set fish_greeting # Disable greeting message.
set -g fish_term24bit 1 # Enable true color support.

fish_vi_key_bindings # Enable vi bindings.

# Fixes cursor shape behavior in vim mode.
set fish_cursor_default block
set fish_cursor_insert block
set fish_cursor_replace_one block
set fish_cursor_replace block
set fish_cursor_external block
set fish_cursor_visual block

function fish_prompt
  set_color blue
  printf "\$ "
  set_color normal
end
