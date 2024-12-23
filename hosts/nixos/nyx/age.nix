{inputs, config, ...}: {
  imports = [inputs.agenix.nixosModules.default];

  age.secrets."services/cachix.dhall" = {
    file = ../../../secrets/service/cachix.dhall.age;
    mode = "0400";
    owner = config.users.users.delay.name;
    path = "${config.users.users.delay.home}/.config/cachix/cachix.dhall";
  };

  age.secrets."services/nix-access-tokens.conf" = {
    file = ../../../secrets/service/nix-access-tokens.conf.age;
    mode = "0400";
    owner = config.users.users.delay.name;
  };
}
