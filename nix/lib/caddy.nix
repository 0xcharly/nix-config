{lib}: let
  uri = import ./uri.nix lib;
in {
  mkReverseProxyConfig = {
    domain,
    host,
    port,
    ...
  }: {
    ${domain}.extraConfig = ''
      import ts_host
      reverse_proxy ${uri.mkAuthority {inherit host port;}};
    '';
  };
}
