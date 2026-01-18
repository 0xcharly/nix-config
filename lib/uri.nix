lib: {
  mkFqn = domain: hostName: "${hostName}.${domain}";

  mkAuthority =
    {
      host,
      port,
      ...
    }:
    "${host}:${toString port}";
}
