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
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    # Weekly updated index: quickly locate nix packages with specific files.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Neovim overlay with personal configuration.
    nvim.url = "github:0xcharly/nix-config-nvim";

    # Alacritty Themes (includes Catppuccin).
    alacritty-theme.url = "github:alexghr/alacritty-theme.nix";

    # macOS only: Homebrew for Nix.
    homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.pre-commit-hooks-nix.flakeModule
        inputs.treefmt-nix.flakeModule

        ./flake/cmd-fmt.nix
        ./flake/devshells.nix
        ./flake/config-manager.nix
      ];

      systems = ["aarch64-darwin" "aarch64-linux" "x86_64-linux"];

      config-manager = {
        root = ./hosts;
        injectArgs = {inherit inputs;};
        # NOTE: the notion of "default" user when username is not specified
        # anywhere in the config currently unsupported.
        # TODO: consider falling back to "default.nix" when username is not
        # specified. Currently needs to support reading the actual username
        # value from somewhere.
        defaultUser = "delay";

        overlays = [
          inputs.alacritty-theme.overlays.default
        ];

        # NixOS hosts.
        nixos.hosts = {
          vm-aarch64.injectArgs = {isCorpManaged = false;}; # Optional.
          vm-linode.injectArgs = {isHeadless = true;};
        };

        # nix-darwin hosts.
        macos = {
          injectArgs = {isHeadless = false;};

          hosts = {
            studio = {}; # Optional.
            mbp-roam = {}; # Optional.

            mbp-delay.injectArgs = {isCorpManaged = true;};
            mbp-delay-roam.injectArgs = {
              isCorpManaged = true;
              migrateHomebrew = true;
            };
          };
        };

        # Home Manager only config for other Linux hosts.
        home = {
          defaultSystem = "x86_64-linux";
          injectArgs = {isHeadless = false;}; # TODO: figure out why this is required.

          users = {
            "delay@linode".injectArgs = {isHeadless = true;};

            "delay@cloudtop-delay".injectArgs = {
              isCorpManaged = true;
              isHeadless = true;
            };
          };
        };
      };

      flake = let
        # overlays = [
        #   inputs.alacritty-theme.overlays.default
        # ];
        #
        # mkDarwinSystem = import ./lib/mk-darwin-system.nix {inherit overlays inputs;};
        # mkHomeOnly = import ./lib/mk-home-only.nix {inherit nixpkgs overlays inputs;};
        # mkNixOSSystem = import ./lib/mk-nixos-system.nix {inherit overlays nixpkgs inputs;};
      in {
        # # NixOS hosts.
        # nixosConfigurations.vm-aarch64 = mkNixOSSystem ./hosts/vm-aarch64.nix {};
        #
        # nixosConfigurations.vm-linode = mkNixOSSystem ./hosts/vm-linode.nix {
        #   isHeadless = true;
        # };
        #
        # # nix-darwin hosts.
        # darwinConfigurations.studio = mkDarwinSystem ./hosts/darwin.nix {};
        # darwinConfigurations.mbp-roam = mkDarwinSystem ./hosts/darwin.nix {};
        #
        # darwinConfigurations.mbp-delay = mkDarwinSystem ./hosts/darwin-corp.nix {
        #   isCorpManaged = true;
        # };
        #
        # darwinConfigurations.mbp-delay-roam = mkDarwinSystem ./hosts/darwin-corp.nix {
        #   isCorpManaged = true;
        #   migrateHomebrew = true;
        # };
        #
        # # Home Manager only config for other Linux hosts.
        # homeConfigurations."delay@linode" = mkHomeOnly {
        #   isHeadless = true;
        # };
        #
        # homeConfigurations."delay@cloudtop-delay" = mkHomeOnly {
        #   isCorpManaged = true;
        #   isHeadless = true;
        # };
      };
    };
}
