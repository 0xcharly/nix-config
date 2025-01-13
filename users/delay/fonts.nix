{
  lib,
  pkgs,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;

  enable = !config.modules.usrenv.isHeadless;
in {
  fonts.fontconfig = {
    inherit enable;
    defaultFonts = {
      monospace = ["Comic Code Ligatures"];
    };
  };

  home.packages = lib.mkIf enable [
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
    # pkgs.maple-mono # Cute, cozy round font.
    pkgs.material-design-icons
    pkgs.mononoki # Used for its @.
    pkgs.noto-fonts-cjk-sans # CJK fonts.
    # pkgs.pixel-code # Fun pixel font.
  ];
}
