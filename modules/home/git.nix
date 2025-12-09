{
  config,
  lib,
  ...
}: {
  programs.git = {
    enable = true;
    userName = lib.mkDefault "Charly Delay";
    userEmail = lib.mkDefault "charly@delay.gg";
    signing = {
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPf5EWFb/MW+1ZdQxDLZJWPrgrtibMcCmmKeCp+QMWBl";
      signByDefault = true;
    };
    ignores = [
      "/.direnv/"
    ];
    difftastic.enable = true;
    extraConfig = {
      branch = {
        autosetuprebase = "always";
        sort = "-committerdate";
      };
      color.ui = true;
      github.user = "0xcharly";
      push.default = "tracking";
      init.defaultBranch = "main";
      gpg.format = "ssh";
      commit.gpgsign = true;
      gitget = {
        root = "${config.home.homeDirectory}/code";
        host = "github.com";
      };
    };
  };
}
