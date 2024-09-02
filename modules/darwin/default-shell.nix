{
  config,
  lib,
  ...
}: let
  # Converts a valid argument to user.shell into a string that points to a shell
  # executable. Logic copied from nix-darwin/modules/system/shells.nix.
  shellPath = v:
    if lib.types.shellPackage.check v
    then "/run/current-system/sw${v.shellPath}"
    else v;

  cfg = config.users;
  createdUsers = builtins.map (v: cfg.users."${v}") config.modules.system.users;
in {
  # Set users shell without giving overwhelming permission on it
  #   https://github.com/LnL7/nix-darwin/issues/811
  # Inspired by https://github.com/LnL7/nix-darwin/blob/cf297a8/modules/users/default.nix#L175
  # Purposely condition this activation script on `knownUsers` being empty to
  # avoid conflicts with the `nix-darwin` implementation.
  # Extends the `users` activation script because `nix-darwin` doesn't run
  # arbitrary user-defined activation scripts.
  #   https://github.com/LnL7/nix-darwin/issues/663
  # https://github.com/LnL7/nix-darwin/blob/cf297a8d/modules/system/activation-scripts.nix#L60
  system.activationScripts.users.text = lib.mkIf (cfg.knownUsers == []) ''
    echo "setting up users' shell..." >&2

    ${lib.concatMapStringsSep "\n" (v: ''
        dscl . -create '/Users/${v.name}' UserShell ${lib.escapeShellArg (shellPath v.shell)}
      '')
      createdUsers}
  '';
}
