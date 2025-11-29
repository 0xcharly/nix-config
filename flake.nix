{
  description = "Nix systems and configs for delay";

  outputs = inputs:
    inputs.blueprint {
      inherit inputs;
      prefix = ./nix;
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

    # Manages home directory, dotfiles and base environment.
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    blueprint = {
      url = "github:numtide/blueprint";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix (community) Unofficial Repository.
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix/release-25.05"; # Catppuccin all the things.
    deploy-rs.url = "github:serokell/deploy-rs"; # System deploy tool.
    disko.url = "github:nix-community/disko"; # Filesystem management.
    golink.url = "github:tailscale/golink"; # go/link service.
    walker.url = "github:abenz1267/walker"; # Launcher.

    nix-config-fonts.url = "github:0xcharly/nix-config-fonts"; # Unfree fonts.
    nix-config-nvim.url = "github:0xcharly/nix-config-nvim"; # Neovim.
    nix-config-secrets.url = "github:0xcharly/nix-config-secrets"; # Secrets management.
    nix-config-shell.url = "github:0xcharly/nix-config-shell"; # Quickshell.

    # macOS only: system configuration with Nix.
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # macOS only: Homebrew for Nix.
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # pieceofenglish.fr
    pieceofenglish.url = "github:0xcharly/pieceofenglish";

    # Formatting.
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  nixConfig = {
    extra-substituters = [
      "https://0xcharly-nixos-config.cachix.org"
      "https://nixos-raspberrypi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "0xcharly-nixos-config.cachix.org-1:qnguqEXJ4bEmJ8ceXbgB2R0rQbFqfWgxI+F7j4Bi6oU="
      "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
    ];
  };
}
