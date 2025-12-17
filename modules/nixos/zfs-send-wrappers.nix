{
  config,
  pkgs,
  ...
}: let
  mkBufferedSshCall = remote_command: ''
    mbuffer -m 1G -s 1M -q \
      | ssh \
          -o IdentitiesOnly=yes \
          -o PasswordAuthentication=no \
          -o KbdInteractiveAuthentication=no \
          -o IdentityFile=${config.age.secrets."keys/zfs_replication_ed25519_key".path} \
          syncoid@dalmore.qyrnl.com "mbuffer -m 1G -s 1M | ${remote_command}"
  '';
in {
  environment.defaultPackages = with pkgs; [
    (writeShellApplication {
      name = "zfs-send-snapshot";
      runtimeInputs = [zfs mbuffer];
      text = ''
        DATASET="$1"
        SNAPSHOT="$2"

        sudo zfs send -Rwp "''${@:3}" "$DATASET@$SNAPSHOT" \
          | ${mkBufferedSshCall "zfs receive -sF $DATASET"}
      '';
    })

    (writeShellApplication {
      name = "zfs-resume-send";
      runtimeInputs = [zfs mbuffer];
      text = ''
        DATASET=$1
        RESUME_TOKEN=$2

        sudo zfs send -t "$RESUME_TOKEN" \
          | ${mkBufferedSshCall "zfs receive -s $DATASET"}
      '';
    })
  ];
}
