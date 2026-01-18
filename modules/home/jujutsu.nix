{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [ jjui ];

  programs.jujutsu = {
    enable = true;
    package = lib.mkDefault pkgs.jujutsu;
    settings = {
      inherit (config.programs.git.settings) user;
      template-aliases."format_timestamp(timestamp)" = "timestamp.ago()";
      ui = {
        default-command = "status";
        diff-formatter = [
          (lib.getExe config.programs.difftastic.package)
          "--color=always"
          "$left"
          "$right"
        ];
        editor = lib.getExe pkgs.nvim;
      };
      merge-tools.mergiraf.program = lib.getExe pkgs.mergiraf;
      signing = {
        behavior = "own";
        backend = "ssh";
        inherit (config.programs.git.signing) key;
      };
    };
  };
}
