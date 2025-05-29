{
  inputs,
  config,
  ...
}: {
  imports = [inputs.nix-config-secrets.homeManagerModules.default];

  age.identityPaths = ["${config.home.homeDirectory}/.ssh/age_home_ssh_host_ed25519_key"];
}
