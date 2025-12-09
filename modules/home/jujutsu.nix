{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.git;
in {
  home.packages = with pkgs; [jjui];

  programs.jujutsu = {
    enable = true;
    package = lib.mkDefault pkgs.jujutsu;
    settings = {
      user = {
        name = cfg.userName;
        email = cfg.userEmail;
      };
      template-aliases."format_timestamp(timestamp)" = "timestamp.ago()";
      ui = {
        default-command = "status";
        diff-formatter = [(lib.getExe pkgs.difftastic) "--color=always" "$left" "$right"];
        editor = lib.getExe pkgs.nvim;
      };
      merge-tools.mergiraf.program = lib.getExe pkgs.mergiraf;
      signing = {
        behavior = "own";
        backend = "ssh";
        key = cfg.signing.key;
      };
    };
  };
}
