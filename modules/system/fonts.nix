{
  config,
  lib,
  pkgs,
  ...
}: {
  fonts = lib.mkIf (!config.modules.usrenv.isHeadless) {
    packages = with pkgs; [
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
      (nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
      material-design-icons
      mononoki
      noto-fonts-cjk-sans
      pixel-code
    ];
  };
}
