{ inputs, ... }:
{ osConfig, ... }:
{
  imports = [ inputs.nix-config-secrets.homeModules.default ];

  age.identityPaths = [
    osConfig.age.secrets."keys/delay/age_hm_ed25519_key".path
  ];
}
