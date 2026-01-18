{ pkgs, ... }:
{
  boot = {
    supportedFilesystems.btrfs = true;
    initrd.supportedFilesystems.btrfs = true;
  };

  environment.systemPackages = with pkgs; [
    httm # Snapshot browsing.
  ];
}
