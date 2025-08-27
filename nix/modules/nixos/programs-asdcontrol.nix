{pkgs, ...}: {
  environment.defaultPackages = with pkgs; [asdcontrol];
  services.udev.extraRules = ''
    KERNEL=="hiddev*", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="1114", GROUP="users", OWNER="root", MODE="0660"
    KERNEL=="hiddev*", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="9243", GROUP="users", OWNER="root", MODE="0660"
  ''; # Studio Display (1114), Pro Display XDR (9243)
}
