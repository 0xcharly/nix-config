{ flake, ... }:
{ pkgs, ... }:
{
  fonts.fontconfig = {
    enable = true;
    defaultFonts =
      let
        inherit (flake.lib.user.gui.fonts)
          emoji
          monospace
          sansSerif
          serif
          ;
      in
      {
        monospace = [ monospace.name ];
        sansSerif = [ sansSerif.name ];
        serif = [ serif.name ];
        emoji = [ emoji.name ];
      };
  };

  home.packages = with pkgs; [
    material-design-icons
    nerd-fonts.symbols-only
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    recursive
  ];
}
