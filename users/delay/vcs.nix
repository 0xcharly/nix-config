{
  config,
  lib,
  pkgs,
  pkgs',
  ...
}: {
  programs.jujutsu = {
    enable = true;
    package = lib.mkDefault pkgs'.jujutsu;
    # TODO: look into using `settings.fix.tools`.
    settings = {
      user = {
        email = "0@0xcharly.com";
        name = "Charly Delay";
      };
      template-aliases."format_timestamp(timestamp)" = "timestamp.ago()";
      ui."default-command" = "status";
      ui.editor = lib.getExe pkgs.nvim;
      signing = {
        behavior = "own";
        backend = "ssh";
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPf5EWFb/MW+1ZdQxDLZJWPrgrtibMcCmmKeCp+QMWBl";
      };
      # Disable inline alternation in diffs, keeps the output consistent.
      diff.color-words.max-inline-alternation = 0;
      # TODO: Consolidate into a "Catppuccin Obsidian" theme flavor.
      colors = {
        "diff removed" = {fg = "#fe9aa4";};
        "diff removed token" = {
          fg = "#fe9fa9";
          bg = "#41262e";
          underline = false;
        };
        "diff added" = {fg = "#a6e3a1";};
        "diff added token" = {
          fg = "#aff3c0";
          bg = "#243c2e";
          underline = false;
        };
      };
    };
  };

  programs.git = {
    enable = true;
    userName = "Charly Delay";
    userEmail = "0@0xcharly.com";
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPf5EWFb/MW+1ZdQxDLZJWPrgrtibMcCmmKeCp+QMWBl";
      signByDefault = true;
    };
    ignores = [
      "/.direnv/"
    ];
    delta.enable = true;
    extraConfig = {
      branch.autosetuprebase = "always";
      color.ui = true;
      github.user = "0xcharly";
      push.default = "tracking";
      init.defaultBranch = "main";
      branch.sort = "-committerdate";
      gpg.format = "ssh";
      commit.gpgsign = true;
      gitget = {
        root = "${config.home.homeDirectory}/code";
        host = "github.com";
      };
    };
  };
}
