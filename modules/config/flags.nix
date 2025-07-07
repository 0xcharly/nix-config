{
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) bool listOf str;

  cfg = config.modules;
in {
  options.modules.flags = {
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

    ssh = {
      installBasicAccessKeys = mkOption {
        type = bool;
        default = cfg.system.security.isBasicAccessTier && !cfg.system.security.isTrustedAccessTier;
        readOnly = true;
        description = ''
          Installs the Basic Access Tier machines' SSH keys.
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
            - Key will be symlinked to `~/.ssh/{key}`
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
        default = cfg.system.roles.beans.sourceOfTruth;
        readOnly = true;
        description = ''
          Adds an entry to the authorized_keys file to allow backing up bean
          files.
        '';
      };
    };

    tailscale = {
      tailnetName = mkOption {
        type = str;
        default = "neko-danio.ts.net";
        readOnly = true;
        description = ''
          Unique name is used when registering DNS entries, sharing your device
          to other tailnets, and issuing TLS certificates.
        '';
      };

      allNodes = mkOption {
        type = listOf str;
        default = ["heimdall" "linode" "linode-arch" "nyx" "helios" "selene"];
        readOnly = true;
        description = ''
          The list of all hosts part of the tailnet.
        '';
      };
    };
  };
}
