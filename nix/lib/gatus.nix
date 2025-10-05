{
  endpoints = {
    mkDnsIPv4Endpoint = domainName: ip: {
      name ? domainName,
      rcode ? "NOERROR",
      conditions ? [],
    }: {
      inherit name;
      group = "dns IPv4";
      url = ip;
      dns = {
        query-name = domainName;
        query-type = "A";
      };
      interval = "1m";
      conditions =
        [
          "[CONNECTED] == true"
          "[DNS_RCODE] == ${rcode}"
        ]
        ++ conditions;
    };

    mkDnsIPv6Endpoint = domainName: ip: {
      name ? domainName,
      rcode ? "NOERROR",
      conditions ? [],
    }: {
      inherit name;
      group = "dns IPv6";
      url = ip;
      dns = {
        query-name = domainName;
        query-type = "AAAA";
      };
      interval = "1m";
      conditions =
        [
          "[CONNECTED] == true"
          "[DNS_RCODE] == ${rcode}"
        ]
        ++ conditions;
    };

    mkPingHostCheck = hostName: {
      name = hostName;
      url = "icmp://${hostName}.qyrnl.com";
      group = "hosts";
      interval = "1m";
      conditions = ["[CONNECTED] == true"];
    };

    mkHttpServiceCheck = name: {domain, ...}: {
      inherit name;
      url = "https://${domain}";
      group = "services";
      interval = "60s";
      conditions = [
        "[STATUS] == 200"
      ];
      alerts = [{type = "gotify";}];
    };

    mkApiCheck = name: url: conditions: {
      inherit name;
      url = "https://${url}";
      conditions = ["[STATUS] == 200"] ++ conditions;
    };
  };
}
