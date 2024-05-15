{pkgs}:
with pkgs; [
  (iosevka-bin.override {variant = "SGr-IosevkaTermCurly";})
  (iosevka-bin.override {variant = "Etoile";})
  (nerdfonts.override {fonts = ["IosevkaTerm" "NerdFontsSymbolsOnly"];})
  font-awesome_6
  material-design-icons
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
]
