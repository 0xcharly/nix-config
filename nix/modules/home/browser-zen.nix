{inputs, ...}: {pkgs, ...}: {
  imports = [inputs.zen-browser.homeModules.beta];

  programs.zen-browser = {
    enable = true;
    nativeMessagingHosts = [pkgs.firefoxpwa];
    policies = import ./browser-mkFirefoxPolicies.nix;
    profiles = import ./browser-mkFirefoxProfiles.nix {
      inherit (pkgs) lib nixos-icons;
      inherit (pkgs.nur.repos.rycee) firefox-addons;
    };
  };
}
