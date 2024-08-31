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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Manages home directory, dotfiles and base environment.
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # macOS system configuration with Nix.
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # We use flake parts to organize our configurations.
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
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

    # Neovim.
    nix-config-nvim.url = "github:0xcharly/nix-config-nvim";

    # 👻
    # ghostty.url = "github:ghostty-org/ghostty";
    nix-config-ghostty = {
      url = "git+ssh://git@github.com/0xcharly/nix-config-ghostty";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-darwin.follows = "nixpkgs-darwin";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
    };

    # Other packages.
    jujutsu.url = "github:martinvonz/jj";
  };

  nixConfig = {
    extra-substituters = ["https://0xcharly-nixos-config.cachix.org"];
    extra-trusted-public-keys = ["0xcharly-nixos-config.cachix.org-1:qnguqEXJ4bEmJ8ceXbgB2R0rQbFqfWgxI+F7j4Bi6oU="];
  };
}
