{
  facts,
  lib,
  uri,
}:
with lib;
let
  # Apply a function to each key in an attribute set, creating a new attribute
  # set. Like `lib.attrsets.mapAttr`, but transform keys instead of values.
  mapAttrsName = transform: mapAttrs' (hostName: value: nameValuePair (transform hostName) value);

  # Fully qualifies hostname keys in the given list of attribute sets.
  mapToFqn = domain: mapAttrsName (uri.mkFqn domain);

  mkKnownHosts =
    hosts:
    hosts
    # Filter out hosts without a key
    |> filterAttrs (_: cfg: cfg ? ssh-ed25519)
    # Rehydrate hosts with aliases
    |> mapAttrsToList (
      host: cfg: [ { ${host} = cfg; } ] ++ (map (alias: { ${alias} = cfg; }) (cfg.aliases or [ ]))
    )
    |> concatLists
    |> mergeAttrsList
    # Create the final map host → key
    |> mapAttrs (_: cfg: { inherit (cfg) ssh-ed25519; });

  internetKnownHosts = mkKnownHosts facts.ssh.internet.knownHosts;
  tailnetKnownHosts = mkKnownHosts facts.wireguard.tailscale.vlan;

  allKnownHosts =
    internetKnownHosts
    // tailnetKnownHosts
    // (mapToFqn facts.domain tailnetKnownHosts) # *.qyrnl.com
    // (mapToFqn facts.wireguard.tailscale.tailnet tailnetKnownHosts) # *.neko-danio.ts.net
  ;

  forEachKnownHostsEntry =
    fn: hosts:
    flatten (mapAttrsToList (host: keys: mapAttrsToList (type: key: fn host type key) keys) hosts);

  mkNixosKnownHostAttrs = host: type: key: {
    "${host}/${type}" = {
      hostNames = singleton host;
      publicKey = concatStringsSep " " [
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
  knownHosts = forEachKnownHostsEntry mkNixosKnownHostAttrs allKnownHosts |> mergeAttrsList;
  knownHostsFile =
    forEachKnownHostsEntry mkKnownHostsFileEntry allKnownHosts |> concatStringsSep "\n";
}
