{ self, ... }:
let
  colors = self.lib.colors.noPrefix;
  no-color = "00000000";
in
{
  flake.homeModules.colors-swaylock = {
    programs.swaylock.settings = with colors; {
      color = surface;
      bs-hl-color = text_rose;
      caps-lock-bs-hl-color = text_rose;
      caps-lock-key-hl-color = text_green;
      inside-color = surface;
      inside-clear-color = surface_blue;
      inside-caps-lock-color = surface_amber;
      inside-ver-color = surface_violet;
      inside-wrong-color = surface_red;
      key-hl-color = text_green;
      layout-bg-color = no-color;
      layout-border-color = no-color;
      layout-text-color = text;
      line-color = no-color;
      line-clear-color = no-color;
      line-caps-lock-color = no-color;
      line-ver-color = no-color;
      line-wrong-color = no-color;
      ring-color = borders;
      ring-clear-color = on_surface_blue;
      ring-caps-lock-color = on_surface_amber;
      ring-ver-color = on_surface_violet;
      ring-wrong-color = on_surface_red;
      separator-color = no-color;
      text-color = text;
      text-clear-color = on_surface_blue;
      text-caps-lock-color = on_surface_amber;
      text-ver-color = on_surface_violet;
      text-wrong-color = on_surface_red;
    };
  };
}
