{
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv) isDarwin;

  adb-scrcpy-pkg = pkgs.writeShellApplication {
    name = "adb-scrcpy";
    runtimeInputs = [pkgs.scrcpy];
    text = builtins.readFile ./bin/adb-scrcpy.sh;
  };
in {
  home.packages =
    [
      (pkgs.writeShellScriptBin "fish-to-zsh-history" (builtins.readFile ./bin/fish-to-zsh-history.sh))
      (pkgs.writeShellScriptBin "term-capabilities" (builtins.readFile ./bin/term-capabilities.sh))
      (pkgs.writeShellScriptBin "term-truecolors" (builtins.readFile ./bin/term-truecolors.sh))

      (pkgs.writeShellApplication {
        name = "generate-gitignore";
        runtimeInputs = [pkgs.curl];
        text = ''curl -sL "https://www.gitignore.io/api/$1"'';
      })
    ]
    ++ lib.optionals isDarwin [
      adb-scrcpy-pkg
      pkgs.sekrets
    ];

  # Raycast expects script attributes to be listed at the top of the file,
  # so a simple wrapper does not work. This *needs* to be a symlink.
  xdg.configFile = lib.optionalAttrs isDarwin {
    "raycast/bin/adb-scrcpy".source = lib.getExe adb-scrcpy-pkg;
  };
}
