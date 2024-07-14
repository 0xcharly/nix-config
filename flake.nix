{
  description = "NixOS systems and configs for delay";

  nixConfig = {
    extra-substituters = ["https://0xcharly-nixos-config.cachix.org"];
    extra-trusted-public-keys = ["0xcharly-nixos-config.cachix.org-1:qnguqEXJ4bEmJ8ceXbgB2R0rQbFqfWgxI+F7j4Bi6oU="];
  };

  inputs = {
    # Pin our primary nixpkgs repository. This is the main nixpkgs repository
    # we'll use for our configurations.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

    # We use the unstable nixpkgs repo for some packages.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";

    # Manages home directory, dotfiles and base environment.
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # macOS system configuration with Nix.
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    pre-commit-hooks,
    ...
  }: let
    supportedSystems = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];

    overlays = [
      inputs.alacritty-theme.overlays.default
    ];

    mkDarwinSystem = import ./lib/mk-darwin-system.nix {
      inherit overlays inputs;
    };

    mkNixOSSystem = import ./lib/mk-nixos-system.nix {
      inherit overlays nixpkgs inputs;
    };

    mkHomeOnly = import ./lib/mk-home-only.nix {
      inherit overlays nixpkgs inputs;
    };
  in
    flake-utils.lib.eachSystem supportedSystems
    (system: let
      pkgs = import nixpkgs {inherit system;};
      shell =
        pkgs.mkShell
        {
          name = "nix-config-devShell";
          buildInputs =
            (with pre-commit-hooks.packages.${system}; [
              # Nix tools.
              alejandra
              markdownlint-cli
              stylua
            ])
            ++ (with pkgs; [
              nixd
            ]);
          shellHook = ''
            ${self.checks.${system}.pre-commit-check.shellHook}
          '';
        };
      pre-commit-check = pre-commit-hooks.lib.${system}.run {
        src = self;
        hooks = {
          alejandra.enable = true;
          markdownlint = {
            enable = true;
            settings.configuration = {
              MD034 = false;
            };
          };
        };
      };
    in {
      devShells.default = shell;
      checks = {inherit pre-commit-check;};
    })
    // {
      # NixOS hosts.
      nixosConfigurations.vm-aarch64 = mkNixOSSystem ./hosts/vm-aarch64.nix {};

      nixosConfigurations.vm-linode = mkNixOSSystem ./hosts/vm-linode.nix {
        isHeadless = true;
      };

      # nix-darwin hosts.
      darwinConfigurations.studio = mkDarwinSystem ./hosts/darwin.nix {};

      darwinConfigurations.mbp-roam = mkDarwinSystem ./hosts/darwin.nix {};

      darwinConfigurations.mbp-delay = mkDarwinSystem ./hosts/darwin-corp.nix {
        isCorpManaged = true;
      };

      darwinConfigurations.mbp-delay-roam = mkDarwinSystem ./hosts/darwin-corp.nix {
        isCorpManaged = true;
        migrateHomebrew = true;
      };

      # Home Manager only config for other Linux hosts.
      homeConfigurations."delay@linode" = mkHomeOnly {
        isHeadless = true;
      };

      homeConfigurations."delay@cloudtop-delay" = mkHomeOnly {
        isCorpManaged = true;
        isHeadless = true;
      };
    };
}
