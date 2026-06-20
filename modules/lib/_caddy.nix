{ uri }:
rec {
  # Caddy’s Automatic HTTPS (ACME) certificate management.
  mkGandiTlsCertificateIssuanceConfig = virtualHost: {
    "(${virtualHost})".extraConfig = ''
      tls {
        resolvers 194.242.2.2 1.1.1.1 8.8.8.8
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
