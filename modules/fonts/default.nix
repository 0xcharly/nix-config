{
  lib,
  pkgs,
  ...
}: {
  fonts = {
    # fontDir.enable is not supported on nix-darwin (fonts are enabled by default).
    fontDir = lib.mkIf (!pkgs.stdenv.isDarwin) {enable = true;};

    packages = with pkgs; [
      (iosevka-bin.override {variant = "SGr-IosevkaTermCurly";})
      (iosevka.override {
        set = "QuasiProportional";
        privateBuildPlan = ''
          [buildPlans.IosevkaQuasiProportional]
          family = "Iosevka QuasiProportional"
          spacing = "quasi-proportional"
          serifs = "sans"
          noCvSs = true
          exportGlyphNames = false
        '';
      })
      (nerdfonts.override {fonts = ["IosevkaTerm" "NerdFontsSymbolsOnly"];})
      font-awesome_6
      material-design-icons
      monaspace
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
    ];
  };
}
