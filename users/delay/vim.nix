{ inputs }:

self: super:

let sources = import ../../nix/sources.nix; in rec {
  customVim = with self; {
    vim-fish = vimUtils.buildVimPlugin {
      name = "vim-fish";
      src = sources.vim-fish;
    };

    vim-fugitive = vimUtils.buildVimPlugin {
      name = "vim-fugitive";
      src = sources.vim-fugitive;
    };

    vim-pgsql = vimUtils.buildVimPlugin {
      name = "vim-pgsql";
      src = sources.vim-pgsql;
    };

    vim-zig = vimUtils.buildVimPlugin {
      name = "vim-zig";
      src = sources.vim-zig;
    };

    vim-nix = vimUtils.buildVimPlugin {
      name = "vim-nix";
      src = sources.vim-zig;
    };

    nvim-auto-hlsearch = vimUtils.buildVimPlugin {
      name = "nvim-auto-hlsearch";
      src = sources.nvim-auto-hlsearch;
    };

    nvim-catppuccin = vimUtils.buildVimPlugin {
      name = "nvim-catppuccin";
      src = sources.nvim-catppuccin;
    };

    nvim-comment = vimUtils.buildVimPlugin {
      name = "nvim-comment";
      src = sources.nvim-comment;
    };

    nvim-conform = vimUtils.buildVimPlugin {
      name = "nvim-conform";
      src = sources.nvim-conform;
    };

    nvim-gitsigns = vimUtils.buildVimPlugin {
      name = "nvim-gitsigns";
      src = sources.nvim-gitsigns;
    };

    nvim-lastplace = vimUtils.buildVimPlugin {
      name = "nvim-lastplace";
      src = sources.nvim-lastplace;
    };

    nvim-lualine = vimUtils.buildVimPlugin {
      name = "nvim-lualine";
      src = sources.nvim-lualine;
    };

    nvim-lspconfig = vimUtils.buildVimPlugin {
      name = "nvim-lspconfig";
      src = sources.nvim-lspconfig;
    };

    nvim-neodev = vimUtils.buildVimPlugin {
      name = "nvim-neodev";
      src = sources.nvim-neodev;
    };

    nvim-nonicons = vimUtils.buildVimPlugin {
      name = "nvim-nonicons";
      src = sources.nvim-nonicons;
    };

    nvim-plenary = vimUtils.buildVimPlugin {
      name = "nvim-plenary";
      src = sources.nvim-plenary;
    };

    nvim-rustacean = vimUtils.buildVimPlugin {
      name = "nvim-rustacean";
      src = sources.nvim-rustacean;
    };

    nvim-surround = vimUtils.buildVimPlugin {
      name = "nvim-surround";
      src = sources.nvim-surround;
    };

    nvim-telescope = vimUtils.buildVimPlugin {
      name = "nvim-telescope";
      src = sources.nvim-telescope;
    };

    nvim-treesitter = vimUtils.buildVimPlugin {
      name = "nvim-treesitter";
      src = sources.nvim-treesitter;
    };

    nvim-treesitter-textobjects = vimUtils.buildVimPlugin {
      name = "nvim-treesitter-textobjects";
      src = sources.nvim-treesitter-textobjects;
    };

    nvim-trouble = vimUtils.buildVimPlugin {
      name = "nvim-trouble";
      src = sources.nvim-trouble;
    };

    nvim-web-devicons = vimUtils.buildVimPlugin {
      name = "nvim-web-devicons";
      src = sources.nvim-web-devicons;
    };

    vim-markdown = vimUtils.buildVimPlugin {
      name = "vim-markdown";
      src = sources.vim-markdown;
    };

    vim-copilot = vimUtils.buildVimPlugin {
      name = "vim-copilot";
      src = sources.vim-copilot;
    };
  };
}
