{ config }:
let
  lua = lua: { __raw = lua; };
  # NOTE: abuse the fact that the value of find_files evaluate to true to return our custom
  # implementation of the picker (which overrides the default parameters).
  kludge = lua: "find_files and function() ${lua} end";
  picker = { name, opts ? {} }: let
    full_opts = opts // {
      previewer = false;
      disable_devicons = true;
    };
  in "require 'telescope.builtin'.${name}(${config.nixvim.helpers.toLuaObject full_opts})";
  smart_find_files = ''
    vim.fn.system [[ git rev-parse --is-inside-work-tree ]]
    if vim.v.shell_error == 0 then
      ${picker { name = "git_files"; }}
    else
      ${picker { name = "find_files"; }}
    end
  '';
  nix_config_files = picker {
    name = "git_files";
    opts = { cwd = "~/code/nixos-config"; };
  };
in {
  enable = true;
  extensions.fzf-native.enable = true;
  settings = {
    defaults = {
      prompt_prefix = " :";
      entry_prefix = "   ";
      selection_caret = "  ";
      layout_strategy = "flex";

      file_previewer = lua "require 'telescope.previewers'.vim_buffer_cat.new";
      grep_previewer = lua "require 'telescope.previewers'.vim_buffer_vimgrep.new";
      qflist_previewer = lua "require 'telescope.previewers'.vim_buffer_qflist.new";

      preview = false;

      mappings = {
        n = {
          "<C-t>" = lua "require 'trouble.providers.telescope'.open_with_trouble";
        };
        i = {
          "<C-t>" = lua "require 'trouble.providers.telescope'.open_with_trouble";
          "<ESC>" = lua "require 'telescope.actions'.close";
          "<C-x>" = false;
          "<C-q>" = lua "require 'telescope.actions'.send_to_qflist";
          "<CR>" = lua "require 'telescope.actions'.select_default";
        };
      };
    };
  };
  keymaps = builtins.mapAttrs (name: value: kludge value) {
    "<LocalLeader>." = nix_config_files;
    "<LocalLeader><Space>" = smart_find_files;
    "<LocalLeader>f" = picker { name = "find_files"; };
    "<LocalLeader>g" = picker { name = "live_grep"; };
    "<LocalLeader>b" = picker { name = "buffers"; };
    "<LocalLeader>j" = picker { name = "jumplist"; };
    "<LocalLeader>s" = picker { name = "lsp_document_symbols"; };
    "<LocalLeader>S" = picker { name = "lsp_dynamic_workspace_symbols"; };
    "<LocalLeader>d" = picker { name = "diagnostics"; };
    "<LocalLeader>?" = picker { name = "help_tags"; };
    "<LocalLeader>m" = picker { name = "man_pages"; };
    "<LocalLeader>*" = picker { name = "grep_string"; };
  };
}
