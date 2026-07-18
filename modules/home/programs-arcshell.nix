{ moduleWithSystem, ... }:
{
  flake.homeModules.programs-arcshell = moduleWithSystem (
    perSystem@{ config, ... }:
    homeManager@{ lib, ... }:
    {
      options = with lib; {
        programs.arcshell = {
          enable = mkEnableOption "Enable Desktop shell";
          package = mkOption {
            type = types.package;
            default = perSystem.config.packages.arcshell;
            description = "The arcshell package to install";
          };
          systemd = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Enable the systemd service for shell";
            };
            target = mkOption {
              type = types.str;
              description = ''
                The systemd target that will automatically start the shell.
              '';
              default = homeManager.config.wayland.systemd.target;
            };
            environment = mkOption {
              type = types.listOf types.str;
              description = "Extra Environment variables to pass to the shell systemd service.";
              default = [ ];
              example = [
                "QT_QPA_PLATFORMTHEME=gtk3"
              ];
            };
          };
          settings = mkOption {
            type = types.attrsOf types.anything;
            default = { };
            description = "Desktop shell settings";
          };
          extraConfig = mkOption {
            type = types.str;
            default = "";
            description = "Desktop shell extra configs written to shell.json";
          };
        };
      };

      config =
        let
          cfg = homeManager.config.programs.arcshell;
        in
        lib.mkIf cfg.enable {
          systemd.user.services.arcshell = lib.mkIf cfg.systemd.enable {
            Unit = {
              Description = "Desktop Shell Service";
              After = [ cfg.systemd.target ];
              PartOf = [ cfg.systemd.target ];
              X-Restart-Triggers = lib.mkIf (cfg.settings != { }) [
                "${homeManager.config.xdg.configFile."arcshell/shell.json".source}"
              ];
            };

            Service = {
              Type = "exec";
              ExecStart = lib.getExe cfg.package;
              Restart = "on-failure";
              RestartSec = "5s";
              TimeoutStopSec = "5s";
              Environment = [
                "QT_QPA_PLATFORM=wayland"
              ]
              ++ cfg.systemd.environment;

              Slice = "session.slice";
            };

            Install = {
              WantedBy = [ cfg.systemd.target ];
            };
          };

          xdg.configFile =
            let
              mkConfig =
                c:
                lib.pipe (if c.extraConfig != "" then c.extraConfig else "{}") [
                  builtins.fromJSON
                  (lib.recursiveUpdate c.settings)
                  builtins.toJSON
                ];
            in
            {
              "arcshell/shell.json".text = mkConfig cfg;
            };
        };
    }
  );

  perSystem =
    { self', pkgs, ... }:
    {
      packages.arcshell = pkgs.callPackage ./arcshell {
        inherit (self'.packages) apdbctl;
        stdenv = pkgs.clangStdenv;
      };

      devShells.arcshell = pkgs.mkShell.override { stdenv = self'.packages.arcshell.stdenv; } {
        inputsFrom = [ self'.packages.arcshell ];
        packages = with pkgs; [
          kdePackages.qtdeclarative

          material-symbols
          self'.packages.arcshell.doto
          nerd-fonts.symbols-only
          recursive
          rubik
        ];
      };
    };
}
