{
  programs.nixvim.globals = {
    mapleader = ",";
    maplocalleader = " ";

    # Disable unused plugins.
    loaded_health = 1;
    loaded_gzip = 1;
    loaded_matchit = 1;
    loaded_rplugin = 1;
    loaded_shada = 1;
    loaded_spellfile = 1;
    loaded_tarPlugin = 1;
    loaded_tohtml = 1;
    loaded_tutor = 1;
    loaded_zipPlugin = 1;

    # Disable unused providers.
    loaded_ruby_provider = 0;
    loaded_perl_provider = 0;
    loaded_python_provider = 0; # Python 2

    # Netrw plugin.
    netrw_browse_split = 0;
    netrw_banner = 0;
    netrw_winsize = 25;

    # Disable overrides by the VIM runtime ftpugin/python.vim.
    # https://github.com/neovim/neovim/commit/2648c3579a4d274ee46f83db1bd63af38fa9e0a7
    python_recommended_style = 0;
  };

  programs.nixvim.opts = {
    number = true;
    relativenumber = true;
    signcolumn = "yes";
    cursorline = true;

    mouse = "a";

    # Large fold level on startup.
    foldcolumn = "1";
    foldlevel = 99;
    foldlevelstart = 99;
    foldenable = true;

    breakindent = true;
    undofile = true;
    belloff = "all";

    # Indentation.
    autoindent = true;
    expandtab = true;
    shiftround = true;
    shiftwidth = 2;
    softtabstop = 2;
    tabstop = 2;
    textwidth = 80;
    wrap = false;

    # Search.
    incsearch = true;
    ignorecase = true;  # Ignore case when searching...
    smartcase = true;   # ... unless there is a capital letter in the query
    splitright = true;  # Prefer windows splitting to the right
    splitbelow = true;  # Prefer windows splitting to the bottom
    updatetime = 50;    # Make updates happen faster
    scrolloff = 8;      # Make it so there are always 8 lines below my cursor

    formatoptions = { # :help formatoptions
      t = false;        # Don't auto-wrap text at 'textwidth'.
      c = false;        # Don't auto-wrap comments using textwidth.
      r = true;         # Insert comment leader on newline in Insert mode.
      # TODO: test drive o=true,/=true.
      o = true;         # "O" and "o" continue comments...
      "/" = true;       # ...unless it's a // comment after a statement.
      q = true;         # Format comments with "gq".
      w = false;        # Don't use trailing whitespace to detect end of paragraphs.
      a = false;        # Don't auto-format paragraphs.
      n = true;         # Detect numbered lists when formatting.
      "2" = false;      # Use indent from the 1st line of a paragraph.
      v = false;        # Don't try to be Vi-compatible.
      b = false;        # Don't try to be Vi-compatible.
      l = true;         # Don't break long lines in insert mode.
      j = true;         # Auto-remove comments leader when joining lines.
    };

    # Message output.
    shortmess = { # :help shortmess
      t = true;
      a = true;
      A = true;
      o = true;
      O = true;
      T = true;
      f = true;
      F = true; # NOTE: this breaks autocommand messages
      s = true;
      c = true;
      W = true;
    };

    grepprg = "rg --hidden --glob '!.git' --no-heading --smart-case --vimgrep --follow $*";
  };

  # Anything that doesn't have (yet) an alternative/dedicated option.
  programs.nixvim.extraConfigLua = ''
    vim.opt.grepformat = vim.opt.grepformat ^ { '%f:%l:%c:%m' }
  '';
}
