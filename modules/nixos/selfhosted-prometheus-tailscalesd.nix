{ flake, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # Bump tailscalesd to 5.0.0
    #   - 25.11 has 3.0.0
    #   - unstable has 4.0.0
    {
      nixpkgs.overlays = [
        (
          final: prev:
          let
            version = "0.5.0";
          in
          {
            tailscalesd = prev.tailscalesd.overrideAttrs (attrs: {
              inherit version;

              src = prev.fetchFromGitHub {
                owner = "cfunkhouser";
                repo = "tailscalesd";
                rev = "v${version}";
                hash = "sha256-FaM2kr3fBC1R2Kgvf5xz4zAw8JQGOmN3fQhHayB/Zs0=";
              };

              vendorHash = "sha256-/nmX0Zqwda5LRC9cmLneU1NJa/VL8vgG284BtjiNTbE=";
            });
          }
        )
      ];
    }
  ];

  options.node.services.prometheus.tailscalesd = with lib; {
    enable = mkEnableOption "Prometheus service discovery for Tailscale";
    port = mkOption {
      description = "The port on which `tailscalesd` exposes the metrics";
      type = types.port;
      default = 9242;
    };
  };

  config =
    let
      cfg = config.node.services.prometheus.tailscalesd;
    in
    lib.mkIf cfg.enable {
      services.prometheus.scrapeConfigs = [
        {
          job_name = "tailscale_node_exporter";
          http_sd_configs = [
            { url = "http://localhost:${toString cfg.port}"; }
          ];
          relabel_configs = [
            {
              source_labels = [ "__meta_tailscale_device_hostname" ];
              target_label = "tailscale_hostname";
            }
            {
              source_labels = [ "__meta_tailscale_device_name" ];
              target_label = "tailscale_name";
            }
            {
              action = "labelmap";
              regex = "__meta_tailscale_device_tags_(.+)";
              replacement = "ts_tag_$1";
            }
            # TODO: consider adding a `action: drop` for host that do not match
            # a "expected to be permanently online" tag.
            {
              source_labels = [ "__address__" ];
              replacement = "$1:${toString config.services.prometheus.exporters.node.port}";
              target_label = "__address__";
            }
          ];
        }
      ];

      systemd.services.tailscalesd = {
        description = "Prometheus Service Discovery for Tailscale";
        after = [ "tailscale.service" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig.ExecStart = "${lib.getExe pkgs.tailscalesd} --localapi --address 127.0.0.1:${toString cfg.port}";
        restartIfChanged = true;
      };
    };
}
