{lib, ...}: {
  programs.keychain.keys = lib.facts.ssh.delay.trusted-keys;
}
