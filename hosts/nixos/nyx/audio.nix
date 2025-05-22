{pkgs, ...}: {
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # Uncomment to use JACK applications.
    jack.enable = true;
  };

  services.pulseaudio.enable = false;

  environment.systemPackages = with pkgs; [
    kdePackages.plasma-pa
    pavucontrol
    pulsemixer
    qjackctl
  ];
}
