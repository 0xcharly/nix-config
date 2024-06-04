{
  config,
  lib,
  ...
}: let
  cfg = config.mule;
in {
  options.mule = {
    enable = lib.mkEnableOption ''
      {command}`nix-darwin` to manage installing/updating/upgrading mule apps and packages.
    '';

    prefix = lib.mkOption {
      type = lib.types.str;
      default = "/usr/local/bin";
      example = "/usr/local/bin";
      description = ''
        The directory where Mule is installed.
      '';
    };

    packages = lib.mkOption {
      type = with lib.types; listOf str;
      default = [];
      example = ["srcfs"];
      description = ''
        List of applications to install using {command}`mule`.
      '';
    };

    config = {
      muleCmd = lib.concatStringsSep " " (
        ["mule" "install"]
        ++ config.packages
      );
    };
  };
  config = {
    system.activationScripts.mule.text = lib.mkIf cfg.enable ''
      echo >&2 "Mule..."
      if [ -f "${cfg.prefix}/mule" ]; then
        PATH="${cfg.prefix}":$PATH ${cfg.muleCmd}
      else
        echo -e "\e[1;31merror: Mule is not installed, skipping...\e[0m" >&2
      fi
    '';
  };
}
