{ lib }:
let
  alert-providers = [
    # FIXME: Linode blocks outgoing SMTP connections
    #   https://techdocs.akamai.com/cloud-computing/docs/send-email
    #   https://www.linode.com/docs/guides/running-a-mail-server/
    #   gomail fails with: dial tcp <ip>:587: i/o timeout
    # "email"
    "gotify"
    "pushover"
  ];

  mkAlertParams =
    {
      enabled ? true,
      description ? "Healthcheck failed",
      send-on-resolved ? true,
      success-threshold ? 1,
      failure-threshold ? 1,
    }:
    {
      inherit
        enabled
        description
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
    builtins.map (type: params // { inherit type; }) alert-providers;

  mkShortAlerts = builtins.map (type: { inherit type; }) alert-providers;
in
{
  inherit mkAlertParams;

  mkDnsIPv4Endpoint =
    domain: nameserver:
    {
      name ? domain,
      rcode ? "NOERROR",
      conditions ? [ ],
    }:
    {
      inherit name;
      group = "dns IPv4";
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
    { domain, ... }:
    {
      inherit name;
      url = "https://${domain}";
      group = "services";
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
      forbidden = [
        ","
        "/"
        "_"
        " "
        "."
        "#"
      ];
      substitutes = builtins.map (_: "-") (lib.range 1 (builtins.length forbidden));
      key = builtins.replaceStrings forbidden substitutes "${group}_${endpoint}";

      parameters = {
        inherit success;
      }
      // (lib.optionalAttrs (error != null) { inherit error; })
      // (lib.optionalAttrs (duration != null) { inherit duration; });

      url =
        let
          encoded_parameters = lib.concatStringsSep "&" (
            lib.attrsToList (key: value: "${key}=${toString value}") parameters
          );
        in
        ''
          https://${domain}/api/v1/endpoints/${key}/external?${encoded_parameters}
        '';
    in
    pkgs.writeShellApplication {
      name = "send-gatus-event-${key}";
      runtimeInputs = with pkgs; [ curl ];
      text = ''
        TOKEN=$(<"${tokenFile}")
        TOKEN="$${TOKEN//$'\n'/}"

        curl -X POST -H "Authorization: Bearer $${TOKEN}" "${url}"
      '';
    };
}
