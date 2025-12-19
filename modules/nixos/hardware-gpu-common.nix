{pkgs, ...}: {
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      libva-vdpau-driver
      libvdpau-va-gl
      mangohud
    ];
    extraPackages32 = with pkgs; [mangohud];
  };
}
