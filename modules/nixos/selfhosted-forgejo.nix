{flake, ...}: {
  config,
  lib,
  ...
}: {
  options.node.services.forgejo = with lib; {
    enable = mkEnableOption "Spin up a Forgejo service";
  };

  config = let
    cfg = config.node.services.forgejo;
    inherit (flake.lib) facts;
  in {
    node.fs.zfs.zpool.root.datadirs = lib.mkIf cfg.enable {
      forgejo = {
        owner = config.services.forgejo.user;
        group = config.services.forgejo.group;
        mode = "0755";
      };
      redis-forgejo = {
        extraOptions = flake.lib.zfs.redis-dataset-options;
        owner = config.services.redis.servers.forgejo.user;
        group = config.services.redis.servers.forgejo.group;
        mode = "0700";
      };
    };

    # Add the forgejo user to the redis-forgejo group to access the UNIX socket.
    users.users."${config.services.forgejo.user}".extraGroups = [
      config.services.redis.servers.forgejo.group
    ];

    services = {
      forgejo = {
        inherit (cfg) enable;
        stateDir = config.node.fs.zfs.zpool.root.datadirs.forgejo.absolutePath;
        repositoryRoot = "/tank/delay/forge/repo";
        lfs = {
          enable = true;
          contentDir = "/tank/delay/forge/data";
        };
        settings = {
          actions.ENABLED = false;
          cache = {
            ADAPTER = "redis";
            HOST = "redis+socket://${config.services.redis.servers.forgejo.unixSocket}";
          };
          oauth2.ENABLED = false;
          openid.ENABLE_OPENID_SIGNIN = false;
          server = {
            DOMAIN = facts.services.forgejo.domain;
            ROOT_URL = "https://${facts.services.forgejo.domain}";
            HTTP_ADDR = "0.0.0.0";
            HTTP_PORT = facts.services.forgejo.port;
            ENABLE_ACME = false;

            START_SSH_SERVER = true;
            SSH_DOMAIN = facts.services.forgejo.ssh.domain;
            SSH_PORT = facts.services.forgejo.ssh.port;
            SSH_LISTEN_HOST = "0.0.0.0";
            SSH_LISTEN_PORT = facts.services.forgejo.ssh.port;
            SSH_SERVER_HOST_KEYS = config.age.secrets."keys/forgejo_ed25519_key".path;
            BUILTIN_SSH_SERVER_USER = "git";
          };
          service.DISABLE_REGISTRATION = true;
          session.COOKIE_SECURE = true;
        };
      };

      redis.servers.forgejo = {
        inherit (cfg) enable;
        port = 0; # Disables TCP.
      };
    };
  };
}
