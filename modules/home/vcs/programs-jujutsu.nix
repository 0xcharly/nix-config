{
  flake.homeModules.programs-jujutsu =
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
          colors = {
            # Highlight the working-copy commit's description: black on white.
            # All three rules are required: jj resolves each style attribute
            # from the most specific matching rule, and the built-in defaults
            # "working_copy description placeholder" (yellow) and
            # "working_copy empty description placeholder" (bright green) are
            # more specific than "working_copy description" — without the
            # overrides the fg would stay yellow/green whenever @ has no
            # description yet.
            "working_copy description" = {
              fg = "black";
              bg = "white";
            };
            "working_copy description placeholder" = {
              fg = "black";
              bg = "white";
            };
            "working_copy empty description placeholder" = {
              fg = "black";
              bg = "white";
            };
          };
          ui = {
            default-command = "status";
            diff-formatter = [
              (lib.getExe config.programs.difftastic.package)
              "--color=always"
              "$left"
              "$right"
            ];
            editor = lib.getExe config.my.programs.nvim.package;
          };
          merge-tools.mergiraf.program = lib.getExe pkgs.mergiraf;
          signing = {
            behavior = "own";
            backend = "ssh";
            inherit (config.programs.git.signing) key;
          };
        };
      };
    };
}
