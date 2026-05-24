{
  config,
  inputs,
  lib,
  ...
}:
with lib;
{
  options.my.hosts = mkOption {
    type = types.lazyAttrsOf (
      types.submodule {
        options = {
          hostPlatform = mkOption {
            type = import inputs.systems |> types.enum;
            description = ''
              The platform where the NixOS configuration will run.

              https://search.nixos.org/options?query=nixpkgs.hostPlatform
            '';
            readOnly = true;
            default = "x86_64-linux";
          };

          stateVersion = mkOption {
            type = types.singleLineStr;
            description = ''
              The first version of NixOS installed on this particular machine,
              used to maintain compatibility with application data (e.g.
              databases) created on older NixOS versions.

              https://search.nixos.org/options?query=system.stateVersion
            '';
            default = config.system.stateVersion;
          };

          nixosModule = mkOption {
            type = types.deferredModule;
            visible = "shallow";
          };

          users = mkOption {
            type = types.attrsOf types.deferredModule;
            visible = "shallow";
          };
        };
      }
    );
  };

  config.flake = {
    nixosConfigurations = flip mapAttrs config.my.hosts (
      hostName:
      {
        hostPlatform,
        stateVersion,

        nixosModule,
        users,
        ...
      }:
      inputs.nixpkgs.lib.nixosSystem {
        modules = [
          nixosModule # NixOS module

          # Home Manager module
          {
            imports = [ inputs.home-manager.nixosModules.default ];

            home-manager = {
              # Injects home.stateVersion into the Home Manager module
              users = flip mapAttrs users (
                _: module:
                mkMerge [
                  module
                  { home = { inherit stateVersion; }; }
                ]
              );
              useGlobalPkgs = true;
              useUserPackages = true;
            };
          }

          # System module
          {
            networking = {
              inherit hostName;
              domain = "qyrnl.com";
            };

            nixpkgs = { inherit hostPlatform; };
            system = { inherit stateVersion; };
          }
        ];
      }
    );

    checks =
      with lib;
      config.flake.nixosConfigurations
      |> mapAttrsToList (
        name: nixos: {
          ${nixos.config.nixpkgs.hostPlatform.system} = {
            "configurations:nixos:${name}" = nixos.config.system.build.toplevel;
          };
        }
      )
      |> mkMerge;
  };
}
