{
  config,
  lib,
  pkgs,
  usrlib,
  ...
} @ args: let
  inherit ((usrlib.hm.getUserConfig args).modules.usrenv) isCorpManaged isLinuxDesktop;
in {
  programs.jujutsu = {
    enable = true;
    package = lib.mkDefault pkgs.jujutsu;
    # TODO: look into using `settings.fix.tools`.
    settings = {
      user = {
        name = "Charly Delay";
        email = "0@0xcharly.com";
      };
      template-aliases."format_timestamp(timestamp)" = "timestamp.ago()";
      ui = {
        "default-command" = "status";
        diff = lib.mkIf (!isCorpManaged || !isLinuxDesktop) {
          # TODO(25.11): Deprecated config: ui.diff.tool is renamed to ui.diff-formatter
          tool = [(lib.getExe pkgs.difftastic) "--color=always" "$left" "$right"];
        };
        diff-formatter = [(lib.getExe pkgs.difftastic) "--color=always" "$left" "$right"];
        editor = lib.getExe pkgs.nvim;
      };
      signing = {
        behavior = "own";
        backend = "ssh";
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPf5EWFb/MW+1ZdQxDLZJWPrgrtibMcCmmKeCp+QMWBl";
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
