{
  facts,
  lib,
}:
let
  uri = import ./uri.nix lib;

  # Apply a function to each key in an attribute set, creating a new attribute
  # set. Like `lib.attrsets.mapAttr`, but transform keys instead of values.
  mapAttrsName =
    transform: lib.mapAttrs' (hostName: value: lib.nameValuePair (transform hostName) value);

  # Fully qualifies hostname keys in the given list of attribute sets.
  mapToFqn = domain: mapAttrsName (uri.mkFqn domain);

  allKnownHosts =
    facts.ssh.internet.knownHosts
    // facts.ssh.wireguard.tailscale.knownHosts
    // (
      # *.qyrnl.com
      mapToFqn facts.domain facts.ssh.wireguard.tailscale.knownHosts
    )
    // (
      # *.neko-danio.ts.net
      mapToFqn facts.wireguard.tailscale.tailnet facts.ssh.wireguard.tailscale.knownHosts
    );

  forEachKnownHostsEntry =
    fn: hosts:
    lib.flatten (
      lib.mapAttrsToList (host: keys: lib.mapAttrsToList (type: key: fn host type key) keys) hosts
    );

  mkNixosKnownHostAttrs = host: type: key: {
    "${host}/${type}" = {
      hostNames = lib.singleton host;
      publicKey = lib.concatStringsSep " " [
        type
        key
      ];
    };
  };
  mkKnownHostsFileEntry =
    host: type: key:
    "${host} ${type} ${key}";
in
{
  knownHosts = lib.mergeAttrsList (forEachKnownHostsEntry mkNixosKnownHostAttrs allKnownHosts);

  knownHostsFile = lib.concatStringsSep "\n" (
    forEachKnownHostsEntry mkKnownHostsFileEntry allKnownHosts
  );
}
