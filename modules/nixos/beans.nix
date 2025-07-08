{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.modules.system.beans;
in
  lib.mkIf cfg.sourceOfTruth {
    # TODO: Make this a flags.ssh.authorizeBeansBackupCommand instead.
    users.users.delay = {
      openssh.authorizedKeys.keys = [
        # Authorize backups of beans file.
        ''command="${lib.getExe pkgs.rrsync} -ro ${config.users.users.${cfg.user}.home}/${cfg.dataDir}/" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGa3cDgdhUeqAP2Bmnew2/SfC6HiXslIUpyHQ8HsUUZO beans-backup''
      ];
    };
  }
