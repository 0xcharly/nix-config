{
  description = "Nix systems and configs for delay";

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        ./hosts
        ./parts
      ];

      systems = ["aarch64-darwin" "aarch64-linux" "x86_64-linux"];
    };

  inputs = {
    # Pin our primary nixpkgs repositories. These are the main nixpkgs
    # repositories we'll use for our configurations.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Hardware-specific NixOS modules.
    nixos-hardware.url = "github:nixos/nixos-hardware";

    # Manages home directory, dotfiles and base environment.
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # macOS system configuration with Nix.
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-24.11";
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

    # macOS only: Homebrew for Nix.
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    # Hyprland and plugins.
    hyprland.url = "github:hyprwm/Hyprland?submodules=1&ref=v0.45.2";
    hy3 = {
      url = "github:outfoxxed/hy3?ref=hl0.45.0";
      inputs.hyprland.follows = "hyprland";
    };

    # Catppuccin all the things.
    catppuccin.url = "github:catppuccin/nix";

    # Secrets management.
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.darwin.follows = "nixpkgs-darwin";
    };

    # We use flake parts to organize our configurations.
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Jujutsu at HEAD.
    jujutsu.url = "github:jj-vcs/jj";

    # Pure and reproducible packaging of binary distributed rust toolchains.
    rust-overlay.url = "github:oxalica/rust-overlay";

    # Unfree fonts.
    nix-config-fonts.url = "github:0xcharly/nix-config-fonts";

    # Shared NixOS configuration.
    nix-config-lib.url = "github:0xcharly/nix-config-lib";

    # Neovim.
    nix-config-nvim.url = "github:0xcharly/nix-config-nvim";

    # Secrets management.
    nix-config-secrets = {
      url = "github:0xcharly/nix-config-secrets";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-darwin.follows = "nixpkgs-darwin";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
      inputs.home-manager.follows = "home-manager";
    };

    # Implementation of The Primeagen's sessionizer script in Zellij.
    zellij-prime-hopper = {
      url = "github:0xcharly/zellij-prime-hopper";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-darwin.follows = "nixpkgs-darwin";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
    };
  };

  nixConfig = {
    extra-substituters = ["https://0xcharly-nixos-config.cachix.org"];
    extra-trusted-public-keys = ["0xcharly-nixos-config.cachix.org-1:qnguqEXJ4bEmJ8ceXbgB2R0rQbFqfWgxI+F7j4Bi6oU="];
  };
}
