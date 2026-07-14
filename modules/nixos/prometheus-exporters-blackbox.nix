{
  flake.nixosModules.prometheus-exporters-blackbox =
    { pkgs, ... }:
    {
      services.prometheus.exporters.blackbox = {
        enable = true;
        configFile = (pkgs.formats.yaml { }).generate "blackbox.yml" {
          modules = {
            icmp = {
              prober = "icmp";
              timeout = "5s";
              icmp.preferred_ip_protocol = "ip4";
            };
            http_2xx = {
              prober = "http";
              timeout = "10s";
              http.preferred_ip_protocol = "ip4";
            };
          };
        };
      };
    };
}
