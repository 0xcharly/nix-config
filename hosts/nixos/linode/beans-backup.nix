{
  config,
  lib,
  pkgs,
  ...
}: {
  # Enable with flags.ssh.authorizeBeansBackupCommand?
  users.users.delay = {
    openssh.authorizedKeys.keys = [
      # Authorize backups of beans file.
      ''command="${lib.getExe pkgs.rrsync} -ro ${config.users.users.delay.home}/beans" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGa3cDgdhUeqAP2Bmnew2/SfC6HiXslIUpyHQ8HsUUZO beans-backup''
    ];
  };
}
