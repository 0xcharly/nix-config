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
    # Pin our primary nixpkgs repositories. These are the main nixpkgs
    # repositories we'll use for our configurations.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Manages home directory, dotfiles and base environment.
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # macOS system configuration with Nix.
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # Filesystem management.
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Weekly updated index: quickly locate nix packages with specific files.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # go/link service.
    golink.url = "github:tailscale/golink";

    # macOS only: Homebrew for Nix.
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Catppuccin all the things.
    catppuccin.url = "github:catppuccin/nix";

    # We use flake parts to organize our configurations.
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    nix-config-fonts.url = "github:0xcharly/nix-config-fonts"; # Unfree fonts.
    nix-config-nvim.url = "github:0xcharly/nix-config-nvim"; # Neovim.
    nix-config-secrets.url = "github:0xcharly/nix-config-secrets"; # Secrets management.
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
