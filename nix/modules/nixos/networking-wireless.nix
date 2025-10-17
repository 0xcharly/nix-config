{
  flake,
  inputs,
  ...
}: {
  config,
  lib,
  ...
}: {
  imports = [
    flake.modules.nixos.networking-common
    inputs.nix-config-secrets.modules.nixos.wireless-passwords
  ];

  # NetworkManager is controlled using either nmcli or nmtui.
  networking.networkmanager = {
    enable = true;
    ensureProfiles = {
      environmentFiles = [config.age.secrets."wireless-passwords.env".path];
      profiles = let
        mkWirelessProfile = id: {
          "profile-${toString id}" = {
            connection = {
              id = "wireless-${toString id}";
              type = "wifi";
            };
            wifi.ssid = "$SSID${toString id}";
            wifi-security = {
              auth-alg = "open";
              key-mgmt = "wpa-psk";
              psk = "$PASS${toString id}";
            };
          };
        };

        personal-profiles = builtins.map mkWirelessProfile (lib.range 1 3);
        google-guest-profile = {
          profile-google-guest = {
            connection = {
              id = "google-guest";
              type = "wifi";
            };
            wifi.ssid = "GoogleGuest";
          };
        };
      in
        lib.mergeAttrsList (personal-profiles ++ [google-guest-profile]);
    };
  };
}
