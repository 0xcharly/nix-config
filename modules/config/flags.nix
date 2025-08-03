{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) bool int listOf str;

  cfg = config.modules;
in {
  options.modules.flags = {
    atuin = {
      enableSync = mkOption {
        type = bool;
        default = pkgs.stdenv.isLinux && !cfg.usrenv.isCorpManaged && cfg.system.networking.tailscaleNode;
        readOnly = true;
        description = ''
          Installs and setups atuin client sync.
        '';
      };

      syncAddress = mkOption {
        type = str;
        default = "https://atuin.qyrnl.com";
        readOnly = true;
        description = ''
          The address of the self-hosted atuin sync server.
        '';
      };
    };

    jujutsu = {
      deprecatedUiDiffTool = mkOption {
        type = bool;
        default = !cfg.usrenv.isCorpManaged || !cfg.usrenv.isLinuxDesktop;
        readOnly = true;
        description = ''
          Creates ui.diff.tool Jujutsu config.

          Deprecated Jujutsu config: ui.diff.tool is renamed to
          ui.diff-formatter in newer versions.

          # TODO(25.11): Remove deprecated config.
        '';
      };
    };

    lockScreen = {
      enable = mkOption {
        type = bool;
        default = cfg.system.security.isHighlyPrivilegedAccessTier;
        readOnly = true;
        description = ''
          Whether to enable the lock screen.
          This has no effect on non-NixOS host.
        '';
      };

      timeout = mkOption {
        type = int;
        default = 600; # 10 minutes.
        readOnly = true;
        description = ''
          The amount of idle time, in seconds, before enabling the lock screen.
        '';
      };
    };

    ssh = {
      installBasicAccessKeys = mkOption {
        type = bool;
        default =
          cfg.system.security.isBasicAccessTier
          && !cfg.system.security.isTrustedAccessTier
          && !cfg.system.security.isHighlyPrivilegedAccessTier;
        readOnly = true;
        description = ''
          Installs the Basic Access Tier machines' SSH keys.
        '';
      };

      installTrustedAccessKeys = mkOption {
        type = bool;
        default = cfg.system.security.isTrustedAccessTier;
        readOnly = true;
        description = ''
          Installs the Trusted Access Tier machines' SSH keys.
        '';
      };

      basicAccessKeys = mkOption {
        type = listOf str;
        default = [
          "github"
          "git_commit_signing"
          "tailscale"
        ];
        readOnly = true;
        description = ''
          The list of SSH keys to install on hosts with Basic Access only (i.e.
          not on Trusted Access or higher hosts).

          For a given `key`:
            - Encrypted key path must be `keys/basic-access/{key}_ed25519_key`
            - Private key will be symlinked to `~/.ssh/{key}`
            - Public key will be symlinked to `~/.ssh/{key}.pub`
        '';
      };

      trustedAccessKeys = mkOption {
        type = listOf str;
        default = [
          "github"
          "git_commit_signing"
          "tailscale"
        ];
        readOnly = true;
        description = ''
          The list of SSH keys to install on hosts with Trusted Access or above.

          For a given `key`:
            - Encrypted key path must be `keys/trusted-access/{key}_ed25519_key`
            - Private key will be symlinked to `~/.ssh/{key}`
            - Public key will be symlinked to `~/.ssh/{key}.pub`
        '';
      };

      declareTailscaleNetworkHosts = mkOption {
        type = bool;
        default = cfg.system.networking.tailscaleNode;
        readOnly = true;
        description = ''
          Declares all Tailscale network nodes (accessible from within the
          network) in the SSH config.
        '';
      };

      declareTailscaleEntryNodeHosts = mkOption {
        type = bool;
        default = cfg.usrenv.isCorpManaged;
        readOnly = true;
        description = ''
          Declares all Tailscale entry nodes (accessible from outside the
          network) in the SSH config.
        '';
      };

      authorizeBeansBackupCommand = mkOption {
        type = bool;
        default = cfg.system.beans.sourceOfTruth;
        readOnly = true;
        description = ''
          Adds an entry to the authorized_keys file to allow backing up bean
          files.
        '';
      };
    };

    taskwarrior = {
      enableSync = mkOption {
        type = bool;
        default = pkgs.stdenv.isLinux && !cfg.usrenv.isCorpManaged && cfg.system.networking.tailscaleNode;
        readOnly = true;
        description = ''
          Installs and setups taskwarrior client sync.
        '';
      };

      syncAddress = mkOption {
        type = str;
        default = "https://tasks.qyrnl.com";
        readOnly = true;
        description = ''
          The address of the self-hosted TaskWarrior sync server.
        '';
      };
    };
  };
}
