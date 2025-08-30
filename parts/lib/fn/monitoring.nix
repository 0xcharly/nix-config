{...}: {
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
  mkPingHomelabEndpoint = hostName: {
    name = hostName;
    group = "hosts";
    url = "icmp://${hostName}.qyrnl.com";
    interval = "1m";
    conditions = ["[CONNECTED] == true"];
  };
  mkHttpServiceEndpoint = name: url: {
    inherit name;
    group = "services";
    url = "https://${url}";
    interval = "60s";
    conditions = [
      "[STATUS] == 200"
    ];
    alerts = [{type = "gotify";}];
  };
  mkApiEndpoint = name: url: conditions: {
    inherit name;
    group = "api";
    url = "https://${url}";
    conditions = ["[STATUS] == 200"] ++ conditions;
  };
}
