{
  config,
  lib,
  ...
}:
{
  options.node.networking.bluetooth = with lib; {
    powerOnBoot = mkEnableOption "Whether to power up the default Bluetooth controller on boot";
    enableFastConnectable = mkEnableOption "When enabled other devices can connect faster to us";
  };

  config.hardware =
    let
      cfg = config.node.networking.bluetooth;
    in
    {
      bluetooth = {
        enable = true;
        inherit (cfg) powerOnBoot;
        settings.General = {
          # Shows battery charge of connected devices on supported
          # Bluetooth adapters. Defaults to 'false'.
          Experimental = true;
          # When enabled other devices can connect faster to us, however
          # the tradeoff is increased power consumption. Defaults to
          # 'false'.
          FastConnectable = cfg.enableFastConnectable;
        };
      };
    };
}
