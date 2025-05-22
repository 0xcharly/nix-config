{
  lib,
  pkgs,
  usrlib,
  ...
} @ args: let
  inherit ((usrlib.hm.getUserConfig args).modules.usrenv) installFonts;
in
  lib.mkIf installFonts {
    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = ["Recursive Mono Casual Static"];
        sansSerif = ["Recursive Sans Casual Static"];
        serif = ["Recursive Sans Linear Static"];
      };
    };

    home.packages = [
      (pkgs.nerdfonts.override {fonts = ["NerdFontsSymbolsOnly"];})
      pkgs.material-design-icons
      pkgs.mononoki # Used for its @.
      pkgs.noto-fonts-cjk-sans # CJK fonts.
      pkgs.recursive # Variable font family for code & UI.
    ];
  }
