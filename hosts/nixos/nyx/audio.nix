{pkgs, ...}: {
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    extraConfig.pipewire.adjust-sample-rate = {
      "context.properties" = {
        "default.clock.rate" = 192000;
        "defautlt.allowed-rates" = [192000 48000 44100];
        "default.clock.quantum" = 4096;
        "default.clock.min-quantum" = 512;
        "default.clock.max-quantum" = 8192;
      };
    };
  };

  services.pulseaudio.enable = false;

  environment.systemPackages = with pkgs; [
    kdePackages.plasma-pa
    pavucontrol
    pulsemixer
    qjackctl
  ];
}
