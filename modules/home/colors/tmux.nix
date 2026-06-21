{ self, inputs, ... }:
let
  inherit (inputs.nixpkgs.lib) mkBefore;
  colors = self.lib.colors.asHexStrings;
in
{
  flake.homeModules.colors-tmux = with colors; {
    programs.tmux.extraConfig = mkBefore ''
      set -ogq @text "${on_surface_statusline}"
      set -ogq @text_session_name "${on_surface_statusline}"
      set -ogq @surface "${surface}"
      set -ogq @surface_statusline "${surface_statusline}"
      set -ogq @indicator_current "${accent_darker}"
      set -ogq @indicator_last "${accent_surface}"
      set -ogq @indicator_inactive "${surface_statusline}"
    '';
  };
}
