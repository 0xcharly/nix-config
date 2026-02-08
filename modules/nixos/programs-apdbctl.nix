{ inputs, ... }:
{ pkgs, ... }:
{
  environment.defaultPackages = [ inputs.apdbctl.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  # Studio Display (1114), Pro Display XDR (9243).
  # KERNEL=="hiddev*", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="1114", GROUP="users", OWNER="root", MODE="0660"
  # KERNEL=="hiddev*", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="9243", GROUP="users", OWNER="root", MODE="0660"
  # SUBSYSTEM=="hidraw", DEVPATH=="*:1.7/????:05AC:1114.????/*", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="1114", MODE="0660", TAG+="uaccess"
  services.udev.extraRules = ''
    SUBSYSTEM=="hidraw", DEVPATH=="*:1.?/????:05AC:9243.????/*", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="9243", MODE="0660", TAG+="uaccess"
  '';
}
