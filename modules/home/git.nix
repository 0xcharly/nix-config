{
  config,
  lib,
  ...
}:
{
  programs = {
    git = {
      enable = true;
      signing = {
        key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPf5EWFb/MW+1ZdQxDLZJWPrgrtibMcCmmKeCp+QMWBl";
        signByDefault = true;
      };
      ignores = [
        "/.direnv/"
      ];
      settings = {
        user = {
          name = lib.mkDefault "Charly Delay";
          email = lib.mkDefault "charly@delay.gg";
        };
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

    difftastic = {
      enable = true;
      git.enable = true;
    };
  };
}
