{ pkgs }:

with pkgs; [
  (iosevka-bin.override { variant = "SGr-IosevkaTermCurly"; })
  (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
  material-design-icons
]
