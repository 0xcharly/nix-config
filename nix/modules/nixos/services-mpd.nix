{flake, ...}: {
  config,
  lib,
  ...
}: {
    services = {
      mpd = {
        enable = true;
        extraConfig = ''
          auto_update "yes"

          audio_output {
            type "pipewire"
            name "MPD PipeWire Output"
          }
        '';
      };
  };
}
