{pkgs, ...}: {
  home.packages = with pkgs; [
    bluetui
    wiremix # Not available on the stable channel yet.
  ];
}
