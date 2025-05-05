{usrlib, ...}: {
  # Install known SSH keys for trusted hosts.
  programs.ssh.knownHosts = usrlib.ssh.nixos.knownHosts;
}
