{
  lib,
  pkgs,
  ...
} @ args: let
  config =
    if args ? osConfig
    then args.osConfig
    else args.config;

  enable = config.modules.usrenv.installFonts;
in {
  fonts.fontconfig = lib.mkIf enable {
    enable = true;
    defaultFonts = {
      monospace = ["Recursive Mono Casual Static"];
      sansSerif = ["Recursive Sans Casual Static"];
      serif = ["Recursive Sans Linear Static"];
    };
  };

  home.packages = lib.mkIf enable [
    (pkgs.nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
    # (pkgs.unfree-fonts.comic-code.override {ligatures = false;})
    # (pkgs.unfree-fonts.comic-code.override {ligatures = true;})
    pkgs.recursive # Variable font family for code & UI.
    # pkgs.maple-mono # Cute, cozy round font.
    pkgs.material-design-icons
    pkgs.mononoki # Used for its @.
    pkgs.noto-fonts-cjk-sans # CJK fonts.
    # pkgs.pixel-code # Fun pixel font.
  ];
}
