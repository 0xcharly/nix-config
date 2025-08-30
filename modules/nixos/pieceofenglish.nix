{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.node.services.pieceofenglish;
  domainName = "pieceofenglish.fr";
in {
  imports = [
    inputs.pieceofenglish.nixosModules.default
    {
      # NOTE: this currently only check that the IPv6 address (the AAAA record)
      # can be resolved, not that the domain can be resolved _over_ IPv6.
      # TODO: also check resolver over IPv6?
      services.gatus.settings.endpoints = let
        # TODO: factorize these definitions with the one in facts (when declared).
        publicIPv4 = "172.237.20.186";

        domainNames = [
          "ns1.pieceofenglish.fr"
          "ns2.pieceofenglish.fr"
        ];
      in
        builtins.concatMap (fun:
          builtins.concatMap (domainName: [
            (fun domainName publicIPv4 {name = "${domainName} 🎯";})
            (fun domainName "8.8.8.8" {name = "${domainName} 🌐";})
          ])
          domainNames) [lib.fn.mkDnsIPv4Endpoint lib.fn.mkDnsIPv6Endpoint]
        ++ [
          (lib.fn.mkDnsIPv4Endpoint "pieceofenglish.fr" "8.8.8.8" {
            name = "pieceofenglish.fr 🌐";
            conditions = ["[BODY] == ${publicIPv4}"];
          })
          (lib.fn.mkHttpServiceEndpoint "Piece of English" "pieceofenglish.fr")
        ];
    }
  ];

  options.node.services.pieceofenglish = {
    enable = lib.mkEnableOption "Whether to spin up a Piece of English service.";
    openFirewall = lib.mkEnableOption "Open firewall ports for Piece of English service";

    bindInterface = lib.mkOption {
      type = lib.types.str;
      example = "eth0";
      description = "The network interface to bind to.";
    };

    publicIPv4 = lib.mkOption {
      type = lib.types.str;
      example = "100.101.102.103";
      description = "Public IPv4 of the node";
    };

    publicIPv6 = lib.mkOption {
      type = lib.types.str;
      example = "2001:db8::1";
      description = "Public IPv6 of the node";
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      pieceofenglish = {
        enable = true;
        # HACK: this should not be necessary and is likely due to a
        # misconfiguration in the exposed module.
        package = inputs.pieceofenglish.packages.x86_64-linux.default;
        baseUrl = domainName;
        environmentFile = config.age.secrets."services/pieceofenglish.env".path;
      };

      coredns = {
        enable = true;

        config = let
          zoneFile = pkgs.writeText domainName ''
            $ORIGIN ${domainName}.
            $TTL    3600

            @       IN SOA   ns.${domainName}. hostmaster.${domainName}. 2025070100 86400 10800 3600000 3600
            @   300 IN NS    ns1.${domainName}.
            @   300 IN NS    ns2.${domainName}.
            ns1 300 IN A     ${cfg.publicIPv4}
            ns1 300 IN AAAA  ${cfg.publicIPv6}
            ns2 300 IN A     ${cfg.publicIPv4}
            ns2 300 IN AAAA  ${cfg.publicIPv6}

            @       IN A     ${cfg.publicIPv4}
            @       IN AAAA  ${cfg.publicIPv6}
            www     IN CNAME @
          '';
        in ''
          ${domainName}:53 {
            errors
            log stdout
            bind ${cfg.bindInterface}
            file ${zoneFile}
          }
          .:53 {
            errors
            log stdout
            bind ${cfg.bindInterface}
            forward . 1.1.1.1:53
          }
        '';
      };

      caddy = {
        enable = true;
        package = pkgs.caddy.withPlugins {
          plugins = ["github.com/caddy-dns/gandi@v1.1.0"];
          hash = "sha256-JZLxPJd/HiM6I+YBHwLtQoMG2uZ92jKmlz5nQK6N5+U=";
        };
        environmentFile = config.age.secrets."services/gandi-creds".path;
        virtualHosts = {
          "(ts_host)".extraConfig = ''
            tls {
              resolvers 1.1.1.1
              dns gandi {env.GANDIV5_PERSONAL_ACCESS_TOKEN}
            }
          '';

          ${domainName}.extraConfig = ''
            import ts_host
            reverse_proxy ${config.services.pieceofenglish.listenAddress}:${toString config.services.pieceofenglish.port}
          '';

          "www.${domainName}".extraConfig = ''
            import ts_host
            reverse_proxy ${config.services.pieceofenglish.listenAddress}:${toString config.services.pieceofenglish.port}
          '';
        };
      };
    };

    # Allow Caddy to bind to 443.
    systemd.services.caddy.serviceConfig = {
      AmbientCapabilities = ["CAP_NET_BIND_SERVICE"];
      EnvironmentFile = config.age.secrets."services/gandi-creds".path;
    };

    networking.firewall = lib.mkIf (cfg.openFirewall) {
      interfaces.${cfg.bindInterface} = {
        allowedTCPPorts = [53 80 443];
        allowedUDPPorts = [53];
      };
    };
  };
}
