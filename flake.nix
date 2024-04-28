{
  description = "NixOS systems and configs for delay";

  inputs = {
    # Pin our primary nixpkgs repository. This is the main nixpkgs repository
    # we'll use for our configurations. Be very careful changing this because
    # it'll impact your entire system.
    # TODO: Change this to the next stable channel (24.05) when it's released.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # We use the unstable nixpkgs repo for some packages.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Build a custom WSL installer
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      # TODO: Change this to the next stable channel (24.05) when it's released.
      # url = "github:nix-community/home-manager/release-24.05";
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      # inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wezterm.url = "github:wez/wezterm?dir=nix";

    nixvim = {
      # If using a stable channel you can use `url = "github:nix-community/nixvim/nixos-<version>"`
      # TODO: Change this to the next stable channel (24.05) when it's released.
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-darwin, darwin, ... }@inputs: let
    mkSystem = import ./lib/mksystem.nix {
      inherit nixpkgs inputs;
    };
  in {
    nixosConfigurations.vm-aarch64 = mkSystem "vm-aarch64" {
      system = "aarch64-linux";
      user   = "delay";
    };

    nixosConfigurations.vm-linode = mkSystem "vm-linode" {
      system = "x86_64-linux";
      user   = "delay";
    };

    darwinConfigurations.darwin = mkSystem "darwin" {
      system   = "aarch64-darwin";
      user     = "delay";
      isDarwin = true;
    };

    darwinConfigurations.darwin-corp = mkSystem "darwin-corp" {
      system   = "aarch64-darwin";
      user     = "delay";
      isDarwin = true;
    };
  };
}
