{inputs, ...}: {
  config,
  lib,
  ...
}: {
  # Nix-managed homebrew.
  imports = [inputs.nix-homebrew.darwinModules.nix-homebrew];

  options.node.homebrew = with lib; {
    extraMasApps = mkOption {
      type = types.attrsOf types.int;
      default = {};
      description = ''
        Additional mas apps to install.
      '';
    };

    extraBrews = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Additional formulae to install.
      '';
    };

    extraCasks = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Additional casks to install.
      '';
    };
  };

  config = {
    nix-homebrew = {
      enable = true; # Install Homebrew under the default prefix.
      user = config.system.primaryUser; # User owning the Homebrew prefix.
    };

    homebrew = let
      cfg = config.node.homebrew;
    in {
      enable = true;
      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
      };
      global = {
        brewfile = true;
        autoUpdate = false;
      };
      masApps =
        {
          Amphetamine = 937984704;
          ColorSlurp = 1287239339;
        }
        // cfg.extraMasApps;
      brews =
        [
          "bitwarden-cli" # Password management automation.
        ]
        ++ cfg.extraBrews;
      casks =
        [
          "1password" # Password manager.
          "bitwarden" # Personal password management.
          "ghostty" # Terminal.
          "proton-pass" # Personal password management.
        ]
        ++ cfg.extraCasks;
    };
  };
}
