{
  config,
  lib,
  ...
}:
lib.mkIf config.modules.system.roles.nixos.protonvpn {
  services.protonvpn = {
    enable = true;

    autostart = false;
    interface = {
      name = "protonvpn0";
      ip = "10.2.0.2/32";
      privateKeyFile = config.age.secrets."services/protonvpn-private-key".path;
      dns = {
        enable = true;
        ip = "10.2.0.1";
      };
    };
    endpoint = {
      publicKey = "7FslkahrdLwGbv4QSX5Cft5CtQLmBUlpWC382SSF7Hw=";
      ip = "103.125.235.19";
      port = 51820;
    };
  };
}
