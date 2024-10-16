{
  config,
  lib,
  pkgs,
  ...
}: {
  fonts = lib.mkIf (!config.modules.usrenv.isHeadless) {
    packages = [
      (pkgs.iosevka.override {
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
      (pkgs.nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
      (pkgs.unfree-fonts.comic-code.override {ligatures = false;})
      (pkgs.unfree-fonts.comic-code.override {ligatures = true;})
      pkgs.material-design-icons
      pkgs.mononoki
      pkgs.noto-fonts-cjk-sans
      pkgs.pixel-code
    ];
  };
}
