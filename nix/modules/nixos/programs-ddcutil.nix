{pkgs, ...}: {
  environment.systemPackages = with pkgs; [ddcutil];
  services.udev.packages = with pkgs; [ddcutil];
}
