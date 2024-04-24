{
  description = "NixOS systems and tools by delay";

  inputs = {
    # Pin our primary nixpkgs repository. This is the main nixpkgs repository
    # we'll use for our configurations. Be very careful changing this because
    # it'll impact your entire system.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    # We use the unstable nixpkgs repo for some packages.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Build a custom WSL installer
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wezterm.url = "github:wez/wezterm?dir=nix";

    # Other packages
    zig.url = "github:mitchellh/zig-overlay";

    # Non-flakes
    nvim-conform.url = "github:stevearc/conform.nvim/v5.6.0";
    nvim-conform.flake = false;
    nvim-treesitter.url = "github:nvim-treesitter/nvim-treesitter/v0.9.2";
    nvim-treesitter.flake = false;
    vim-copilot.url = "github:github/copilot.vim/v1.29.0";
    vim-copilot.flake = false;
  };

  outputs = { self, nixpkgs, home-manager, darwin, ... }@inputs: let
    # Overlays is the list of overlays we want to apply from flake inputs.
    overlays = [
      inputs.zig.overlays.default
    ];

    mkSystem = import ./lib/mksystem.nix {
      inherit overlays nixpkgs inputs;
    };
  in {
    nixosConfigurations.vm-aarch64 = mkSystem "vm-aarch64" {
      system = "aarch64-linux";
      user   = "delay";
    };

    nixosConfigurations.vm-aarch64-prl = mkSystem "vm-aarch64-prl" rec {
      system = "aarch64-linux";
      user   = "delay";
    };

    nixosConfigurations.vm-aarch64-utm = mkSystem "vm-aarch64-utm" rec {
      system = "aarch64-linux";
      user   = "delay";
    };

    nixosConfigurations.vm-intel = mkSystem "vm-intel" rec {
      system = "x86_64-linux";
      user   = "delay";
    };

    nixosConfigurations.wsl = mkSystem "wsl" {
      system = "x86_64-linux";
      user   = "delay";
      wsl    = true;
    };

    darwinConfigurations.macbook-pro-m3 = mkSystem "macbook-pro-m3" {
      system = "aarch64-darwin";
      user   = "delay";
      darwin = true;
    };
  };
}
