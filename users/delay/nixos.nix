{ pkgs, inputs, ... }:

{
  # https://github.com/nix-community/home-manager/pull/2408
  environment.pathsToLink = [ "/share/fish" ];

  # Add ~/.local/bin to PATH
  environment.localBinInPath = true;

  # Since we're using fish as our shell
  programs.fish.enable = true;

  users.users.delay = {
    isNormalUser = true;
    home = "/home/delay";
    extraGroups = [ "docker" "wheel" ];
    shell = pkgs.fish;
    hashedPassword = "$6$hty0MeXqIVM0ClKt$6KiNbz5lDxjQOESemC40.T/aK4IOGLgY7YnlgJ./ltd/lVUPRGRCE4fAvKeDJ2v5r7mmmC43gm72zjGmwcbNL1";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP4Jr8wJUXhECjbSXlGPpLFAN0Zq+eY6n4w+0ezoMxFK delay"
    ];
  };

  nixpkgs.overlays = import ../../lib/overlays.nix ++ [
    (import ./vim.nix { inherit inputs; })
  ];
}
