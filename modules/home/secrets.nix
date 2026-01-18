{ inputs, ... }:
{ osConfig, ... }:
{
  imports = [ inputs.nix-config-secrets.modules.home.blueprint ];

  age.identityPaths = [
    osConfig.age.secrets."keys/delay/age_hm_ed25519_key".path
  ];
}
