{
  description = "Nix systems and configs for delay";

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        ./hosts
        ./parts
      ];

      systems = ["aarch64-darwin" "x86_64-linux"];
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Manages home directory, dotfiles and base environment.
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Convenience helpers for flake organization.
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # Nix (community) Unofficial Repository.
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko.url = "github:nix-community/disko"; # Filesystem management.
    golink.url = "github:tailscale/golink"; # go/link service.
    catppuccin.url = "github:catppuccin/nix"; # Catppuccin all the things.
    walker.url = "github:abenz1267/walker"; # Launcher.

    nix-config-fonts.url = "github:0xcharly/nix-config-fonts"; # Unfree fonts.
    nix-config-nvim.url = "github:0xcharly/nix-config-nvim"; # Neovim.
    nix-config-secrets.url = "github:0xcharly/nix-config-secrets"; # Secrets management.

    # macOS only: system configuration with Nix.
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # macOS only: Homebrew for Nix.
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  nixConfig = {
    extra-substituters = [
      "https://0xcharly-nixos-config.cachix.org"
    ];
    extra-trusted-public-keys = [
      "0xcharly-nixos-config.cachix.org-1:qnguqEXJ4bEmJ8ceXbgB2R0rQbFqfWgxI+F7j4Bi6oU="
    ];
  };
}
