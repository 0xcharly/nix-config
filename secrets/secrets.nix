let
  key = import ./keys.nix;

  inherit (key) mkTrustedPublicKeys;
  inherit (key) servers workstations;
in {
  "service/github-auth-token".publicKeys = mkTrustedPublicKeys (workstations ++ servers);
}
