{pkgs, ...}: {
  boot = {
    supportedFilesystems = ["btrfs"];
    initrd.supportedFilesystems = ["btrfs"];
  };

  environment.systemPackages = with pkgs; [
    httm # Snapshot browsing.
  ];
}
