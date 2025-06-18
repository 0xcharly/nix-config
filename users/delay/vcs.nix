{
  config,
  lib,
  pkgs,
  usrlib,
  ...
} @ args: let
  inherit ((usrlib.hm.getUserConfig args).modules) flags;
in {
  programs.jujutsu = {
    enable = true;
    package = lib.mkDefault pkgs.jujutsu;
    settings = {
      user = {
        name = config.programs.git.userName;
        email = config.programs.git.userEmail;
      };
      template-aliases."format_timestamp(timestamp)" = "timestamp.ago()";
      ui =
        {
          "default-command" = "status";
          diff-formatter = [(lib.getExe pkgs.difftastic) "--color=always" "$left" "$right"];
          editor = lib.getExe pkgs.nvim;
        }
        // lib.optionalAttrs flags.jujutsu.deprecatedUiDiffTool {
          # TODO(25.11): Deprecated config: ui.diff.tool is renamed to ui.diff-formatter
          diff.tool = config.programs.jujutsu.settings.ui.diff-formatter;
        };
      signing = {
        behavior = "own";
        backend = "ssh";
        key = config.programs.git.signing.key;
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
    difftastic.enable = true;
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
