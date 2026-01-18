{
  description = "Nix systems and configs for delay";

  outputs =
    inputs:
    let
      blueprint = inputs.blueprint { inherit inputs; };
      deploy-rs = import ./hive inputs blueprint;
    in
    blueprint
    // {
      inherit (deploy-rs) deploy;
      checks = blueprint.checks // deploy-rs.checks;
    };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # Manages home directory, dotfiles and base environment.
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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

    deploy-rs.url = "github:serokell/deploy-rs"; # System deploy tool.
    disko.url = "github:nix-community/disko"; # Filesystem management.
    golink.url = "github:tailscale/golink"; # go/link service.

    nix-config-colorscheme.url = "github:0xcharly/nix-config-colorscheme"; # Custom colorscheme.
    nix-config-fonts.url = "github:0xcharly/nix-config-fonts"; # Unfree fonts.
    nix-config-nvim.url = "github:0xcharly/nix-config-nvim"; # Neovim.
    nix-config-secrets.url = "github:0xcharly/nix-config-secrets"; # Secrets management.
    nix-config-shell.url = "github:0xcharly/nix-config-shell"; # Quickshell.

    # macOS only: system configuration with Nix.
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
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
    experimental-features = [
      "nix-command"
      "flakes"
      "pipe-operators"
    ];

    extra-substituters = [ "https://0xcharly-nixos-config.cachix.org" ];
    extra-trusted-public-keys = [
      "0xcharly-nixos-config.cachix.org-1:qnguqEXJ4bEmJ8ceXbgB2R0rQbFqfWgxI+F7j4Bi6oU="
    ];
  };
}
