{
  programs.nixvim.autoGroups = {
    HighlightYank = { clear = true; };
    TrimWhitespace = { clear = true; };
  };

  programs.nixvim.autoCmd = [
    {
      desc = "Remove trailing whitespace on save";
      event = "BufWritePre";
      group = "TrimWhitespace";
      pattern = "*";
      command = "%s/\\s\\+$//e";
    }
    {
      desc = "Flash yanked text";
      event = "TextYankPost";
      group = "HighlightYank";
      pattern = "*";
      callback = {
        __raw = ''
          function()
            vim.highlight.on_yank { higroup = 'IncSearch', timeout = 40 }
          end
        '';
      };
    }
  ];
}
