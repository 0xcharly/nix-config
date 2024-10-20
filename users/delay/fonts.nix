{
  lib,
  pkgs,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;
in {
  fonts.fontconfig.enable = config.modules.usrenv.enableProfileFont;

  # TODO: reconcile with modules/systems/fonts.nix once verified that it works.
  home.packages = lib.mkIf config.modules.usrenv.enableProfileFont [
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
    pkgs.maple-mono
    pkgs.material-design-icons
    pkgs.mononoki
    pkgs.noto-fonts-cjk-sans
    pkgs.pixel-code
  ];
}
