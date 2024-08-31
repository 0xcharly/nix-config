{inputs, ...}: let
  inherit (inputs) self;

  # mkAgenixSecret streamlines agenix secret files creating while propagating
  # secure defaults.
  # Unless explicitly overridden, the secret will be owned by `root:root`, and
  # have `mode` 400. The `file` argument is relative to `${self}/secrets`.
  mkAgenixSecret = file: {
    owner ? "root",
    group ? "root",
    mode ? "400",
  }: {
    file = "${self}/secrets/${file}";
    inherit group owner mode;
  };
in {
  age.secrets = {
    github-auth-token = mkAgenixSecret "service/github-auth-token" {owner = "delay";};
  };
}
