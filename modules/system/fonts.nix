{
  config,
  lib,
  pkgs,
  ...
}: {
  fonts = lib.mkIf (!config.modules.usrenv.isHeadless) {
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
      mononoki
      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji
    ];
  };
}
