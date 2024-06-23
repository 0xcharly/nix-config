{
  config,
  lib,
  ...
}: let
  cfg = config.mule;

  muleCmd = lib.concatStringsSep " " (
    ["mule" "install"]
    ++ cfg.packages
  );
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
  };
  config = {
    # Installing script as part of the Homebrew activation script.
    # https://github.com/LnL7/nix-darwin/issues/663.
    system.activationScripts.homebrew.text = lib.mkIf cfg.enable (lib.mkAfter ''
      echo >&2 "Mule..."
      if [ -f "${cfg.prefix}/mule" ]; then
        PATH="${cfg.prefix}":$PATH ${muleCmd}
      else
        echo -e "\e[1;31merror: Mule is not installed, skipping...\e[0m" >&2
      fi
    '');
  };
}
