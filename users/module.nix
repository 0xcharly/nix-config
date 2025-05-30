{
  config,
  inputs',
  lib,
  pkgs,
  pkgs',
  self',
  self,
  usrlib,
  ...
}: let
  inherit (self) inputs;
  inherit (lib.modules) mkDefault mkForce;
  inherit (lib.attrsets) genAttrs;
in {
  home-manager = {
    # Tell home-manager to be as verbose as possible.
    verbose = true;

    # Use the system configuration’s pkgs argument.
    # This ensures parity between nixos' pkgs and hm's pkgs.
    useGlobalPkgs = true;

    # Enable the usage user packages through the users.users.<name>.packages
    # option
    useUserPackages = true;

    # Move existing files to the .hm.old suffix rather than failing with a very
    # long error message about it
    backupFileExtension = "hm.old";

    # Additional specialArgs passed to Home Manager.
    # For reference, the config argument in system can be accessed in
    # home-manager through osConfig without us passing it here.
    extraSpecialArgs = {inherit inputs' inputs pkgs' self' self usrlib;};

    # Per-user Home Manager configurations.
    # The function below generates an attribute set of users where users come
    # from a list in usrenv. Each user in this list is mapped to an attribute
    # set to generate the format Home-Manager expects, i.e.
    #
    #   {
    #     "username" = path;
    #   }
    #
    # The system expects user directories to be found in the present directory,
    # or will fail with directory not found errors.
    users = genAttrs (builtins.attrNames config.modules.system.users) (name: ./${name} + /home.nix);

    # Additional configuration that should be set for any existing and future users
    # declared in this module. Any "shared" configuration between users may be passed
    # here.
    sharedModules = [
      {
        options.isNixOS = lib.options.mkOption {
          type = lib.types.bool;
          default = pkgs.stdenv.isLinux;
          readOnly = true;
          description = ''
            A flag allowing to distinguish between HM running on NixOS and
            standalone HM setups.
          '';
        };
      }

      {
        # Ensure that HM uses the same Nix package as the system.
        nix.package = mkForce config.nix.package;

        # The state version indicates which default settings are in effect and
        # will therefore help avoid breaking program configurations.
        home.stateVersion = mkDefault "24.05";

        # I don't care about HM news.
        news.display = "silent";

        # Allow HM to manage itself when in standalone mode.
        # This makes the home-manager command available to users.
        programs.home-manager.enable = true;

        # Try to save some space by not installing variants of the home-manager
        # manual. Unlike what the name implies, this section is for home-manager
        # related manpages only, and does not affect whether or not manpages of
        # actual packages will be installed.
        manual = {
          manpages.enable = false;
          html.enable = false;
          json.enable = false;
        };
      }
    ];
  };
}
