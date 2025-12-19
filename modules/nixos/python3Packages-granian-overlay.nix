# This package is a Paperless-ng dependency.
# Tests are broken in nixos-25.11 because TLS certificates are no longer valid.
# The patch to fix the tests has been merged into release-25.11 but hasn't made
# it to nixos-25.11 yet.
#
# TODO: delete once github:nixos/nixpkgs#471742 is merged in nixos-25.11
# https://github.com/NixOS/nixpkgs/pull/471742
# https://nixpkgs-tracker.ocfox.me/?pr=471742
{
  nixpkgs.overlays = [
    (final: prev: let
      overlay = self: super: {
        granian = super.granian.overridePythonAttrs (attrs: {
          patches =
            (attrs.patches or [])
            ++ [
              (prev.fetchurl {
                # Refresh expired TLS certificates for tests
                url = "https://github.com/emmett-framework/granian/commit/189f1bed2effb4a8a9cba07b2c5004e599a6a890.patch";
                hash = "sha256-7FgVR7/lAh2P5ptGx6jlFzWuk24RY7wieN+aLaAEY+c=";
              })
            ];
        });
      };
    in {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [overlay];
    })
  ];
}
