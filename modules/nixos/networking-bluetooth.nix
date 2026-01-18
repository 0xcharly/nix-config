{
  config,
  lib,
  ...
}:
{
  options.node.networking.bluetooth = with lib; {
    powerOnBoot = mkEnableOption "Whether to power up the default Bluetooth controller on boot";
    enableA2DPSink = mkEnableOption "Allow headsets will generally try to connect using the A2DP profile";
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
        }
        // lib.optionalAttrs cfg.enableA2DPSink {
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
}
