{pkgs, ...}: {
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;

    # Uncomment to use JACK applications.
    jack.enable = true;
  };

  environment.systemPackages = with pkgs; [
    pavucontrol
    plasma-pa
    qjackctl
  ];
}
