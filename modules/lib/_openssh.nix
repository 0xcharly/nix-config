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

  tailnetKnownHosts =
    facts.wireguard.tailscale.vlan
    # Filter out hosts without a key
    |> filterAttrs (_: cfg: cfg ? ssh-ed25519)
    # Rehydrate hosts with an alias
    |> mapAttrsToList (
      host: cfg: [ { ${host} = cfg; } ] ++ (if cfg ? alias then [ { ${cfg.alias} = cfg; } ] else [ ])
    )
    |> concatLists
    |> mergeAttrsList
    # Create the final map host → key
    |> mapAttrs (_: cfg: { inherit (cfg) ssh-ed25519; });
  allKnownHosts =
    facts.ssh.internet.knownHosts
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
