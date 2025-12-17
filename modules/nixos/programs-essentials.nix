{pkgs, ...}: {
  environment.defaultPackages = with pkgs; [
    bmon
    rsync
  ];
}
