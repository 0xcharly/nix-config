{
  mkDnsIPv4Endpoint = domain: nameserver: {
    name ? domain,
    rcode ? "NOERROR",
    conditions ? [],
  }: {
    inherit name;
    group = "dns IPv4";
    url = nameserver;
    dns = {
      query-name = domain;
      query-type = "A";
    };
    interval = "10m";
    conditions =
      [
        "[CONNECTED] == true"
        "[DNS_RCODE] == ${rcode}"
      ]
      ++ conditions;
  };

  mkDnsIPv6Endpoint = domain: nameserver: {
    name ? domain,
    rcode ? "NOERROR",
    conditions ? [],
  }: {
    inherit name;
    group = "dns IPv6";
    url = nameserver;
    dns = {
      query-name = domain;
      query-type = "AAAA";
    };
    interval = "10m";
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
    interval = "5m";
    conditions = ["[CONNECTED] == true"];
  };

  mkHttpServiceCheck = name: {domain, ...}: {
    inherit name;
    url = "https://${domain}";
    group = "services";
    interval = "5m";
    conditions = [
      "[STATUS] == 200"
    ];
    alerts = [{type = "gotify";}];
  };

  mkApiCheck = name: {
    url,
    conditions,
  }: {
    inherit name;
    group = "api";
    url = "https://${url}";
    interval = "5m";
    conditions = ["[STATUS] == 200"] ++ conditions;
  };
}
