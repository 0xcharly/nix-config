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
    homebrew,
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

    mkSystem = import ./lib/mksystem.nix {
      inherit homebrew overlays nixpkgs inputs;
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
              luacheck
              stylua
            ])
            ++ (with pkgs; [
              lua-language-server
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
          # luacheck.enable = true;
          markdownlint = {
            enable = true;
            settings.configuration = {
              MD034 = false;
            };
          };
          stylua.enable = true;
        };
      };
    in {
      devShells.default = shell;
      checks = {inherit pre-commit-check;};
    })
    // {
      nixosConfigurations.vm-aarch64 = mkSystem {
        configuration = ./hosts/vm-aarch64.nix;
      };

      nixosConfigurations.vm-linode = mkSystem {
        configuration = ./hosts/vm-linode.nix;
        isHeadless = true;
      };

      darwinConfigurations.studio = mkSystem {
        configuration = ./hosts/darwin.nix;
        isDarwin = true;
      };

      darwinConfigurations.mbp-roam = mkSystem {
        configuration = ./hosts/darwin.nix;
        isDarwin = true;
      };

      darwinConfigurations.mbp-delay = mkSystem {
        configuration = ./hosts/darwin-corp.nix;
        isCorpManaged = true;
        isDarwin = true;
      };

      darwinConfigurations.mbp-delay-roam = mkSystem {
        configuration = ./hosts/darwin-corp.nix;
        isCorpManaged = true;
        isDarwin = true;
      };
    };
}
