{
  lib,
  pkgs,
  ...
} @ args: let
  inherit ((lib.user.getUserConfig args).modules.usrenv) installFonts;
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

    home.packages = with pkgs; [
      material-design-icons
      nerd-fonts.symbols-only
      noto-fonts-cjk-sans # CJK fonts.
      recursive # Variable font family for code & UI.
      unfree-fonts.comic-code
      (unfree-fonts.comic-code.override {ligatures = true;})
    ];
  }
