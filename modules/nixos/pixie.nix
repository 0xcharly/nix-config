{
  config,
  inputs,
  pkgs,
  ...
}: let
  sys = inputs.nixpkgs.lib.nixosSystem {
    inherit (pkgs) system;
    modules = [
      ({modulesPath, ...}: {
        imports = [(modulesPath + "/installer/netboot/netboot-minimal.nix")];
        config = {
          # This can be updated with each release since this is the netboot image.
          system.stateVersion = "24.11";

          nix.settings.experimental-features = ["nix-command" "flakes"];

          services.openssh = {
            enable = true;
            openFirewall = true;

            settings = {
              PasswordAuthentication = false;
              KbdInteractiveAuthentication = false;
            };
          };

          users.users.root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFajk9JzPmFuD8eatva7e798DPMBr3bIiI1B1PVTXift netboot"
          ];

          environment.systemPackages = with pkgs; [
            duf # Modern `df` alternative.
            tree # List the content of directories in a tree-like format.
            yazi # File explorer that supports Kitty image protocol.
            nvim # Our own package installed by overlay.
          ];
        };
      })
    ];
  };

  inherit (sys.config.system) build;
in {
  services.pixiecore = {
    enable = true;
    openFirewall = true;
    dhcpNoBind = true; # Use existing DHCP server.

    mode = "boot";
    kernel = "${build.kernel}/bzImage";
    initrd = "${build.netbootRamdisk}/initrd";
    cmdLine = "init=${build.toplevel}/init loglevel=4 boot.shellOnFail";
    debug = true;
  };

  assertions = [
    {
      assertion = config.services.pixiecore.enable -> (pkgs.system == "x86_64-linux" && config.modules.stdenv.isNixOS);
      message = "Pixiecore is only supported on x86_64-linux NixOS.";
    }
  ];
}
