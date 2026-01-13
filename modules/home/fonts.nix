{
  flake,
  inputs,
  ...
}: {pkgs, ...}: {
  fonts.fontconfig = {
    enable = true;
    defaultFonts = let
      inherit (flake.lib.user.gui.fonts) emoji monospace sansSerif serif;
    in {
      monospace = [monospace.name];
      sansSerif = [sansSerif.name];
      serif = [serif.name];
      emoji = [emoji.name];
    };
  };

  home.packages = with pkgs; [
    material-design-icons
    nerd-fonts.symbols-only
    noto-fonts-cjk-sans # CJK fonts
    noto-fonts-monochrome-emoji # Monochrome emojis
    rubik

    inputs.nix-config-fonts.packages.${stdenv.hostPlatform.system}.pragmatapro
    inputs.nix-config-fonts.packages.${stdenv.hostPlatform.system}.sys
  ];
}
