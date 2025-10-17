# Apps that should only be installed on personal devices (i.e. non-corp).
{
  homebrew = {
    masApps = {
      Xcode = 497799835; # Xcode is installed out-of-band on corp devices.
    };
    casks = [
      "beeper" # Messaging.
      "bitwarden" # Personal password management.
      "bitwarden-cli" # Password management automation.
      "firefox@developer-edition" # Firefox, for isolates.
      "google-chrome" # When there's no alternatives.
      "obsidian" # Notes.
      "proton-pass" # Personal password management.
      "protonvpn" # Private network.
      "tailscale-app" # Personal VPN network.
      "transmission"
      "vlc" # Media player.
    ];
  };
}
