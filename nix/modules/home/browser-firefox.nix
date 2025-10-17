{pkgs, ...}: {
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;
    languagePacks = ["en_US" "fr_FR" "ja_JP"];
    policies = import ./browser-mkFirefoxPolicies.nix;
    profiles = import ./browser-mkFirefoxProfiles.nix {
      inherit (pkgs) lib nixos-icons;
      inherit (pkgs.nur.repos.rycee) firefox-addons;
    };
  };
}
