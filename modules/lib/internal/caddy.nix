{ uri }:
rec {
  # Caddy’s Automatic HTTPS (ACME) certificate management.
  mkGandiTlsCertificateIssuanceConfig = virtualHost: {
    "(${virtualHost})".extraConfig = ''
      tls {
        # No Mullvad DNS (194.242.2.2) here: it refuses plain port-53 queries
        # from outside the VPN. Resolvers are only used for zone detection:
        # the local propagation check is disabled (propagation_timeout -1)
        # because polling public recursives right after record creation
        # negative-caches the answer (Gandi SOA minimum 300s) for longer than
        # the check window, failing every first issuance. Let's Encrypt
        # validates against Gandi's authoritative servers directly; the fixed
        # delay covers the Gandi API -> authoritative propagation lag.
        resolvers 1.1.1.1 8.8.8.8
        propagation_delay 30s
        propagation_timeout -1
        dns gandi {env.GANDIV5_PERSONAL_ACCESS_TOKEN}
      }
    '';
  };

  mkReverseProxyConfig =
    {
      domain,
      host,
      port,
      import ? "",
      aliases ? [ ],
      ...
    }:
    {
      ${domain} = {
        extraConfig = ''
          ${if (import != "") then "import ${import}" else ""}
          reverse_proxy ${uri.mkAuthority { inherit host port; }}
        '';
        serverAliases = aliases;
      };
    };

  mkRedirectConfig =
    {
      from,
      to,
      import ? "",
      ...
    }:
    {
      "${from}".extraConfig = ''
        ${if (import != "") then "import ${import}" else ""}
        redir https://${to}{uri}
      '';
    };

  mkWwwRedirectConfig =
    {
      domain,
      import ? "",
      ...
    }:
    mkRedirectConfig {
      inherit import;
      from = "www.${domain}";
      to = domain;
    };
}
