{
  description = "Nix systems and configs for delay";

  nixConfig = {
    extra-substituters = ["https://0xcharly-nixos-config.cachix.org"];
    extra-trusted-public-keys = ["0xcharly-nixos-config.cachix.org-1:qnguqEXJ4bEmJ8ceXbgB2R0rQbFqfWgxI+F7j4Bi6oU="];
  };

  inputs = {
    # Pin our primary nixpkgs repositories. These are the main nixpkgs repository
    # we'll use for our configurations.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-darwin.url = "github:NixOS/nixpkgs/nixpkgs-24.05-darwin";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Manages home directory, dotfiles and base environment.
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # macOS system configuration with Nix.
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
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
    homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    # Personal config manager.
    nix-config-manager = {
      url = "github:0xcharly/nix-config-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-darwin.follows = "nixpkgs-darwin";
      inputs.nixpkgs-unstable.follows = "nixpkgs-unstable";
    };

    # Alacritty Themes (includes Catppuccin).
    alacritty-theme.url = "github:alexghr/alacritty-theme.nix";
    # Neovim rust plugin, offered via flakes.
    rustaceanvim = {
      url = "github:mrcjkb/rustaceanvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.nix-config-manager.flakeModule
        inputs.git-hooks-nix.flakeModule
        inputs.treefmt-nix.flakeModule

        ./flake/cmd-fmt.nix
        ./flake/devshells.nix
      ];

      systems = ["aarch64-darwin" "aarch64-linux" "x86_64-linux"];

      config-manager = {
        root = ./.;
        final = false; # This config is extended by a private corp-specific one.
        overlays = [
          inputs.alacritty-theme.overlays.default
          inputs.rustaceanvim.overlays.default
        ];

        # NOTE: automatically backing up existing files is currently unsupported
        # for standalone home-manager setups.
        # See https://github.com/nix-community/home-manager/issues/5649.
        # Instead, we the `-b <backup-file-extension>` to `home-manager switch`.

        # NOTE: the notion of "default" user when username is not specified
        # anywhere in the config is currently unsupported.
        # TODO: consider falling back to "default.nix" when username is not
        # specified. Currently needs to support reading the actual username
        # value from somewhere.
        defaultUser = "delay";

        # Home Manager only config for other Linux hosts.
        # NOTE: because this section is used to define standalone home configs,
        # it is not an appropriate place to put user-specific options (because
        # these home-manager configuration options are also passed to systems).
        # TODO: distinguish between system options and user options.
        home.defaultSystem = "x86_64-linux";
      };
    };
}
