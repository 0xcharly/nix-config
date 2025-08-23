{...}: {
  mkPingHomelabEndpoint = hostName: {
    name = hostName;
    url = "icmp://${hostName}.qyrnl.com";
    group = "hosts";
    interval = "1m";
    conditions = ["[CONNECTED] == true"];
  };
  mkHttpServiceEndpoint = name: url: {
    inherit name;
    url = "https://${url}";
    group = "services";
    interval = "60s";
    conditions = [
      "[STATUS] == 200"
    ];
    alerts = [{type = "gotify";}];
  };
}
