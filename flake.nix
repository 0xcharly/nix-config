{
  description = "NixOS systems and configs for delay";

  nixConfig = {
    extra-substituters = [ "https://0xcharly-nixos-config.cachix.org" ];
    extra-trusted-public-keys = [ "0xcharly-nixos-config.cachix.org-1:qnguqEXJ4bEmJ8ceXbgB2R0rQbFqfWgxI+F7j4Bi6oU=" ];
  };

  inputs = {
    # Pin our primary nixpkgs repository. This is the main nixpkgs repository
    # we'll use for our configurations.
    # TODO: Change this to the next stable channel (24.05) when it's released.
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # We use the unstable nixpkgs repo for some packages.
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      # TODO: Change this to the next stable channel (24.05) when it's released.
      # url = "github:nix-community/home-manager/release-24.05";
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvim.url = "github:0xcharly/nix-config-nvim";

    darwin = {
      url = "github:LnL7/nix-darwin";
      # inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Last stable release.
    wezterm.url = "github:wez/wezterm/20240203-110809-5046fc22?dir=nix";
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

    mkSystem = import ./lib/mksystem.nix {
      inherit nixpkgs inputs;
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
          markdownlint.enable = true;
          # nixpkgs-fmt.enable = true;
          stylua.enable = true;
        };
      };
    in {
      devShells = {default = shell;};
      checks = {inherit pre-commit-check;};
    })
    // {
      nixosConfigurations.vm-aarch64 = mkSystem "vm-aarch64" {
        system = "aarch64-linux";
        user = "delay";
      };

      nixosConfigurations.vm-linode = mkSystem "vm-linode" {
        system = "x86_64-linux";
        user = "delay";
      };

      darwinConfigurations.darwin = mkSystem "darwin" {
        system = "aarch64-darwin";
        user = "delay";
        isDarwin = true;
      };

      darwinConfigurations.darwin-corp = mkSystem "darwin-corp" {
        system = "aarch64-darwin";
        user = "delay";
        isDarwin = true;
      };
    };
}
