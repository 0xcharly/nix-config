{pkgs, ...}: {
  # Since we're using Fish as our shell.
  programs.fish.enable = true;

  users.users.delay = {
    isNormalUser = true;
    home = "/home/delay";
    extraGroups = ["docker" "wheel"];
    shell = pkgs.fish;
    # Create a hashed password with `nix-shell -p mkpasswd --run "mkpasswd -m yescrypt"`
    hashedPassword = "$y$j9T$TrN/LFDpdc5kkHZc6bkyV1$b4TqAfjBY2xuwmAUHVbco.cyI43JzOjs1dXt5ey3c.3";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB/bLz52u0dTFYTfJelVbXbU+VK7H4OXgre/8Mgx1+cq"
    ];
  };
}
