{
  config,
  pkgs,
  ...
}: {
  # Since we're using Fish as our shell.
  programs.fish.enable = true;

  # Creates the group `delay`.
  users.groups.delay = {};

  # Creates the user `delay`.
  users.users.delay = {
    isNormalUser = true;
    inherit (config.modules.system.users.delay) home;
    group = "delay";
    extraGroups = ["users" "wheel"];
    shell = pkgs.fish;
    # Create a hashed password with `nix-shell -p mkpasswd --run "mkpasswd -m yescrypt"`
    hashedPasswordFile = config.age.secrets."passwd/delay".path;
  };
}
