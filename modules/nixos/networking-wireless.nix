{
  flake,
  inputs,
  ...
}:
{
  config,
  lib,
  ...
}:
{
  imports = [
    flake.modules.nixos.networking-common
    inputs.nix-config-secrets.modules.nixos.wireless-config
  ];

  # NetworkManager is controlled using either nmcli or nmtui.
  networking.networkmanager = {
    enable = true;
    ensureProfiles = {
      environmentFiles = [ config.age.secrets."wireless-config.env".path ];
      profiles =
        let
          mkWirelessProfile = id: {
            "profile-${toString id}" = {
              connection = {
                id = "$SSID${toString id}";
                type = "wifi";
                autoconnect = "$AUTO${toString id}";
              };
              wifi = {
                mode = "$MODE${toString id}";
                ssid = "$SSID${toString id}";
              };
              wifi-security = {
                key-mgmt = "$MGMT${toString id}";
                psk = "$PASS${toString id}";
              };
            };
          };

          personal-profiles = map mkWirelessProfile (lib.range 1 5);
          google-guest-profile = {
            profile-google-guest = {
              connection = {
                id = "Google-Guest";
                type = "wifi";
              };
              wifi.ssid = "Google-Guest";
            };
          };
        in
        lib.mergeAttrsList (personal-profiles ++ [ google-guest-profile ]);
    };
  };
}
