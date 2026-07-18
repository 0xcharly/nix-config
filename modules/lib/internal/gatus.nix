{ lib }:
let
  # NOTE: Linode blocks outgoing SMTP connections by default.
  #   https://techdocs.akamai.com/cloud-computing/docs/send-email
  #   https://www.linode.com/docs/guides/running-a-mail-server/
  #   gomail fails with: dial tcp <ip>:587: i/o timeout
  alert-providers = [
    "email"
    "gotify"
    "pushover"
  ];

  mkAlertParams =
    {
      enabled ? true,
      send-on-resolved ? true,
      success-threshold ? 1,
      failure-threshold ? 1,
    }:
    {
      inherit
        enabled
        send-on-resolved
        success-threshold
        failure-threshold
        ;
    };

  mkAlerts =
    { ... }@args:
    let
      params = mkAlertParams args;
    in
    map (type: params // { inherit type; }) alert-providers;

  mkShortAlerts = map (type: { inherit type; }) alert-providers;

  # PTR query names. Gatus claims to convert a bare IP automatically
  # (client/client.go, v5.35.0), but its config validation FQDNs the
  # query-name first ("172.237.13.18." fails net.ParseIP), so the conversion
  # never fires — derive the .arpa form here instead.
  # "172.237.13.18" -> "18.13.237.172.in-addr.arpa"
  ipv4PtrName =
    ip: lib.concatStringsSep "." (lib.reverseList (lib.splitString "." ip)) + ".in-addr.arpa";
  # "2600:3c18::2000:4fff:fe5e:fe68" -> "8.6.e.f.<...>.8.1.c.3.0.0.6.2.ip6.arpa"
  ipv6PtrName =
    ip:
    let
      halves = lib.splitString "::" ip;
      groups = s: lib.filter (g: g != "") (lib.splitString ":" s);
      left = groups (builtins.elemAt halves 0);
      right = if builtins.length halves > 1 then groups (builtins.elemAt halves 1) else [ ];
      zeros = lib.genList (_: "0") (8 - builtins.length left - builtins.length right);
      nibbles = lib.stringToCharacters (
        lib.toLower (lib.concatMapStrings (lib.fixedWidthString 4 "0") (left ++ zeros ++ right))
      );
    in
    lib.concatStringsSep "." (lib.reverseList nibbles) + ".ip6.arpa";
in
{
  inherit mkAlertParams;

  mkDnsIPv4Endpoint =
    domain: nameserver:
    {
      name ? domain,
      group ? "dns IPv4",
      rcode ? "NOERROR",
      conditions ? [ ],
    }:
    {
      inherit name group;
      url = nameserver;
      dns = {
        query-name = domain;
        query-type = "A";
      };
      interval = "10m";
      conditions = [
        "[CONNECTED] == true"
        "[DNS_RCODE] == ${rcode}"
      ]
      ++ conditions;
      alerts = mkShortAlerts;
    };

  mkDnsIPv6Endpoint =
    domain: nameserver:
    {
      name ? domain,
      rcode ? "NOERROR",
      conditions ? [ ],
    }:
    {
      inherit name;
      group = "dns IPv6";
      url = nameserver;
      dns = {
        query-name = domain;
        query-type = "AAAA";
      };
      interval = "10m";
      conditions = [
        "[CONNECTED] == true"
        "[DNS_RCODE] == ${rcode}"
      ]
      ++ conditions;
      alerts = mkShortAlerts;
    };

  mkTcpCheck = name: target: {
    inherit name;
    url = "tcp://${target}";
    group = "mail";
    interval = "5m";
    conditions = [ "[CONNECTED] == true" ];
    alerts = mkShortAlerts;
  };

  mkHttpCheck =
    name: url:
    {
      group ? "services",
    }:
    {
      inherit name group url;
      interval = "1m";
      conditions = [ "[STATUS] == 200" ];
      alerts = mkShortAlerts;
    };

  # Reverse-DNS (PTR) check against a public resolver; [BODY] is the
  # dot-terminated PTR target. Accepts a bare IPv4 or IPv6 address.
  mkRdnsCheck = name: ip: fqdn: {
    inherit name;
    url = "8.8.8.8";
    group = "mail";
    dns = {
      query-name = if lib.hasInfix ":" ip then ipv6PtrName ip else ipv4PtrName ip;
      query-type = "PTR";
    };
    interval = "10m";
    conditions = [
      "[CONNECTED] == true"
      "[DNS_RCODE] == NOERROR"
      "[BODY] == ${fqdn}."
    ];
    alerts = mkShortAlerts;
  };

  mkPingHostCheck = hostName: {
    name = hostName;
    url = "icmp://${hostName}.qyrnl.com";
    group = "hosts";
    interval = "5m";
    conditions = [ "[CONNECTED] == true" ];
    alerts = mkShortAlerts;
  };

  mkHttpServiceCheck =
    name:
    {
      domain,
      group ? "services",
      ...
    }:
    {
      inherit name group;
      url = "https://${domain}";
      interval = "5m";
      conditions = [
        "[STATUS] == 200"
      ];
      alerts = mkShortAlerts;
    };

  mkApiCheck =
    name:
    {
      url,
      conditions,
    }:
    {
      inherit name;
      group = "api";
      url = "https://${url}";
      interval = "5m";
      conditions = [ "[STATUS] == 200" ] ++ conditions;
      alerts = mkShortAlerts;
    };

  mkPushBasedExternalEndpoint =
    name:
    {
      group ? "cron",
      token ? "$EXTERNAL_ENDPOINTS_AUTH_TOKEN",
      heartbeat ? "0",
    }:
    {
      inherit name group token;
      heartbeat.interval = heartbeat;
      alerts = mkAlerts { failure-threshold = 1; };
    };

  mkPushBasedExternalPostRequest =
    {
      pkgs,
      domain,
      tokenFile,
      group,
      endpoint,
      success ? false,
      error ? null,
      duration ? null,
    }:
    let
      # Mirrors Gatus' key generation (config/key/key.go, v5.35.0):
      # each part is lowercased and sanitized separately, then joined with "_".
      forbidden = [
        ","
        "/"
        "_"
        " "
        "."
        "#"
        "+"
        "&"
      ];
      substitutes = map (_: "-") (lib.range 1 (builtins.length forbidden));
      sanitize = s: builtins.replaceStrings forbidden substitutes (lib.toLower s);
      key = "${sanitize group}_${sanitize endpoint}";

      parameters = {
        success = lib.boolToString success;
      }
      // (lib.optionalAttrs (error != null) { inherit error; })
      // (lib.optionalAttrs (duration != null) { inherit duration; });

      url =
        let
          encoded_parameters = lib.concatStringsSep "&" (
            lib.mapAttrsToList (key: value: "${key}=${toString value}") parameters
          );
        in
        "https://${domain}/api/v1/endpoints/${key}/external?${encoded_parameters}";
    in
    pkgs.writeShellApplication {
      name = "send-gatus-event-${key}";
      runtimeInputs = with pkgs; [ curl ];
      text = ''
        # The token file is an env file declaring AUTH_TOKEN.
        # shellcheck disable=SC1091
        source "${tokenFile}"

        curl -sS --fail-with-body -X POST -H "Authorization: Bearer ''${AUTH_TOKEN}" "${url}"
      '';
    };
}
