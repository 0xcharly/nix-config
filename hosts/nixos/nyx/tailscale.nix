{
  services.tailscale.enable = true;
  networking = {
    nameservers = ["100.100.100.100" "8.8.8.8" "192.168.86.1"];
    search = ["neko-danio.ts.net"];
  };
}
