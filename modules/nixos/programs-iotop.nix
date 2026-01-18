{
  programs.iotop.enable = true;

  # https://github.com/NixOS/nixpkgs/issues/160361
  boot.kernel.sysctl = {
    "kernel.task_delayacct" = 1;
  };
}
