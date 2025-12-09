{
  config,
  lib,
  pkgs,
  ...
}: {
  config = let
    cfg = config.node.services.gatus;

    # TODO(unstable): Switch to pkgs'.gatus when this lands on unstable.
    # https://github.com/NixOS/nixpkgs/pull/412797
    package = pkgs.gatus.overrideAttrs rec {
      version = "5.23.2";

      src = pkgs.fetchFromGitHub {
        owner = "TwiN";
        repo = "gatus";
        rev = "v${version}";
        hash = "sha256-b/UQwwyspOKrW9mRoq0zJZ41lNLM+XvGFlpxz+9ZMco=";
      };

      vendorHash = "sha256-jMNsd7AiWG8vhUW9cLs5Ha2wmdw9SHjSDXIypvCKYqk=";
    };
  in {
    services.gatus = {
      inherit package;
    };

    # TODO(25.11): Remove once this lands on stable.
    # https://github.com/NixOS/nixpkgs/pull/415879
    systemd.services.gatus = lib.mkIf cfg.enable {
      serviceConfig = {
        # See https://github.com/prometheus-community/pro-bing#linux.
        AmbientCapabilities = "CAP_NET_RAW";
        CapabilityBoundingSet = "CAP_NET_RAW";
        NoNewPrivileges = true;
      };
    };
  };
}
