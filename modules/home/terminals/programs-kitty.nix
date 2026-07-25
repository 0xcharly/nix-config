{ self, ... }:
{
  flake.homeModules.programs-kitty = {
    imports = [ self.homeModules.theme-kitty ];

    programs.kitty = {
      enable = true;
      shellIntegration = {
        enableBashIntegration = true;
        enableZshIntegration = true;
        enableFishIntegration = true;
      };
      extraConfig = ''
        window_padding_width 0
        confirm_os_window_close 0
      '';
    };
  };
}
