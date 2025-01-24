{
  inputs',
  lib,
  pkgs,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;
  inherit (config.modules.usrenv) sshAgent;
  inherit (pkgs.stdenv) isDarwin;

  homeDirectory = config.modules.system.users.delay.home;
  codeDirectory = homeDirectory + "/code";
  use1PasswordSshAgent = isDarwin && (sshAgent == "1password");
in {
  programs.jujutsu = {
    enable = true;
    # Install jujutsu from HEAD.
    package = inputs'.jujutsu.packages.jujutsu;
    settings =
      lib.recursiveUpdate {
        user = {
          email = "0@0xcharly.com";
          name = "Charly Delay";
        };
        template-aliases."format_timestamp(timestamp)" = "timestamp.ago()";
        ui."default-command" = "status";
        ui.pager = lib.getExe pkgs.delta;
        ui.diff.format = "git";
        git.subprocess = true; # Shell out to `git` instead of libgit2.
        signing = {
          sign-all = true;
          backend = "ssh";
          key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPf5EWFb/MW+1ZdQxDLZJWPrgrtibMcCmmKeCp+QMWBl";
        };
      }
      (lib.optionalAttrs use1PasswordSshAgent {signing.backends.ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";});
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
      gpg = {
        format = "ssh";
        ssh.program = lib.mkIf use1PasswordSshAgent "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      };
      commit.gpgsign = true;
      gitget = {
        root = codeDirectory;
        host = "github.com";
      };
    };
  };
}
