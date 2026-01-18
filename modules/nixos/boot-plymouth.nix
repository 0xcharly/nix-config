{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.node.boot.plymouth = with lib; {
    theme = mkOption {
      type = types.str;
      default = "glitch";
      description = ''
        Splash screen theme.

        https://github.com/adi1090x/plymouth-themes
      '';
    };
  };

  config.boot =
    let
      cfg = config.node.boot.plymouth;
    in
    {
      plymouth = {
        enable = true;
        inherit (cfg) theme;
        themePackages = with pkgs; [
          (adi1090x-plymouth-themes.override {
            selected_themes = [ cfg.theme ]; # Filter out unused themes.
          })
        ];
      };

      # Enable "Silent boot".
      consoleLogLevel = 3;
      initrd.verbose = false;
      kernelParams = [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "udev.log_priority=3"
        "rd.systemd.show_status=auto"
      ];

      # Hide the OS choice for bootloaders.
      # It's still possible to open the bootloader list by pressing any key.
      # It will just not appear on screen unless a key is pressed.
      loader.timeout = 0;
    };
}
