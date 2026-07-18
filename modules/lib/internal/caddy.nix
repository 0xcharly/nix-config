{ uri }:
rec {
  # Caddy’s Automatic HTTPS (ACME) certificate management.
  mkGandiTlsCertificateIssuanceConfig = virtualHost: {
    "(${virtualHost})".extraConfig = ''
      tls {
        # No Mullvad DNS (194.242.2.2) here: it refuses plain port-53 queries
        # from outside the VPN, and certmagic's ACME propagation check fails
        # hard on a REFUSED instead of trying the next resolver.
        resolvers 1.1.1.1 8.8.8.8
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
