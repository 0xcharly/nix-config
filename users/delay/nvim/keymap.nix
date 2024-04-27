{ config, lib, ... }:
{
  programs.nixvim.keymaps = let
    normal = lib.mapAttrsToList (key: action: {
      mode = "n";
      inherit action key;
    })
    {
      "<Space>" = "<Nop>";
      "<ScrollWheelLeft>" = "<Nop>";
      "<ScrollWheelRight>" = "<Nop>";

      # Helix-inspired mappings.
      "U" = "<C-r>";
      "gn" = ":bnext<CR>";
      "gp" = ":bprevious<CR>";

      "Y" = "yg$";
      "n" = "nzzzv";
      "N" = "Nzzzv";
      "J" = "mzJ`z";
      "<C-d>" = "<C-d>zz";
      "<C-u>" = "<C-u>zz";

      # Better yank & delete.
      "<LocalLeader>y" = "\"+y";
      "<LocalLeader>Y" = "\"+Y";
      "<LocalLeader>d" = "\"_d";

      "<C-Left>" = "<C-w>h";
      "<C-Down>" = "<C-w>j";
      "<C-Up>" = "<C-w>k";
      "<C-Right>" = "<C-w>l";
    };
    insert = lib.mapAttrsToList (key: action: {
      mode = "i";
      inherit action key;
    })
    {
      # Better virtual paste.
      "<C-v>" = "<C-o>\"+p";

      "<C-Left>" = "<C-\\><C-N><C-w>h";
      "<C-Down>" = "<C-\\><C-N><C-w>j";
      "<C-Up>" = "<C-\\><C-N><C-w>k";
      "<C-Right>" = "<C-\\><C-N><C-w>l";
    };
    command = lib.mapAttrsToList (key: action: {
      mode = "c";
      inherit action key;
    })
    {
      # Better virtual paste.
      "<C-v>" = "<C-r>+";
    };
    visual = lib.mapAttrsToList (key: action: {
      mode = "x";
      inherit action key;
    })
    {
      # Better virtual paste.
      "<LocalLeader>p" = "\"_dP";
    };
    visual_and_select = lib.mapAttrsToList (key: action: {
      mode = "v";
      inherit action key;
    })
    {
      "<Space>" = "<Nop>";

      "J" = ":m '>+1<cr>gv=gv";
      "K" = ":m '<-2<cr>gv=gv";

      # Better yank & delete.
      "<LocalLeader>y" = "\"+y";
      "<LocalLeader>d" = "\"_d";
    };
    terminal = lib.mapAttrsToList (key: action: {
      mode = "t";
      inherit action key;
    })
    {
      "<Esc><Esc>" = "<C-\\><C-n>";
      "<C-Space>" = "<Space>";
      "<S-Space>" = "<Space>";

      "<C-Left>" = "<C-\\><C-N><C-w>h";
      "<C-Down>" = "<C-\\><C-N><C-w>j";
      "<C-Up>" = "<C-\\><C-N><C-w>k";
      "<C-Right>" = "<C-\\><C-N><C-w>l";
    };
    normal_expr = lib.mapAttrsToList (key: action: {
      mode = "n";
      inherit action key;
    })
    {
      # Remap for dealing with word wrap.
      "k" = "v:count == 0 ? 'gk' : 'k'";
      "j" = "v:count == 0 ? 'gj' : 'j'";
    };
    normal_lua = lib.mapAttrsToList (key: action: {
      mode = "n";
      lua = true;
      inherit action key;
    })
    {
      # Remap for dealing with word wrap.
      "[d" = "vim.diagnostic.goto_prev";
      "]d" = "vim.diagnostic.goto_next";
      "<leader>e" = "vim.diagnostic.open_float";
      "<leader>q" = "vim.diagnostic.setloclist";

      # File explorer.
      "<LocalLeader>pv" = "vim.cmd.Ex";

      # Pane creation.
      "<LocalLeader>ws" = "vim.cmd.split";
      "<LocalLeader>wv" = "vim.cmd.vsplit";

      # Tab navigation.
      "<A-Left>" = "vim.cmd.tabprev";
      "<A-Right>" = "vim.cmd.tabnext";

      # Formatting (see ./conform-nvim.nix).
      "cf" = ''
        function()
          require 'conform'.format { async = true, lsp_fallback = true }
        end
      '';
    };
    insert_lua = lib.mapAttrsToList (key: action: {
      mode = "i";
      inherit action key;
    })
    {
      # Tab navigation.
      "<A-Left>" = "vim.cmd.tabprev";
      "<A-Right>" = "vim.cmd.tabnext";
    };
  in
    config.nixvim.helpers.keymaps.mkKeymaps {
      options.silent = true;
    } (normal ++ insert ++ command ++ visual ++ visual_and_select ++ terminal) ++
    config.nixvim.helpers.keymaps.mkKeymaps {
      options.expr = true;
      options.silent = true;
    } (normal_expr) ++
    config.nixvim.helpers.keymaps.mkKeymaps {
      options.silent = true;
    } (normal_lua ++ insert_lua);
}
