{
  flake,
  inputs,
  ...
}: {pkgs, ...}: {
  fonts.fontconfig = {
    enable = true;
    defaultFonts = let
      inherit (flake.lib.user.gui.fonts) monospace sansSerif serif;
    in {
      monospace = [monospace.name];
      sansSerif = [sansSerif.name];
      serif = [serif.name];
    };
  };

  home.packages = with pkgs; [
    material-design-icons
    nerd-fonts.symbols-only
    noto-fonts-cjk-sans # CJK fonts.
    recursive # Variable font family for code & UI.

    inputs.nix-config-fonts.packages.${system}.comic-code
  ];
}
