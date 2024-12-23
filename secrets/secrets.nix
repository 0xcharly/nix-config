let
  key = import ./keys.nix;

  inherit (key) mkTrustedPublicKeys;
  inherit (key) servers workstations;
in {
  "service/cachix.dhall.age".publicKeys = mkTrustedPublicKeys (workstations ++ servers);
  "service/nix-access-tokens.conf.age".publicKeys = mkTrustedPublicKeys (workstations ++ servers);
}
