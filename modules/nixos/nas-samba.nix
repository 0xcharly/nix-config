{
  config,
  lib,
  usrlib,
  ...
}:
lib.mkIf (usrlib.bool.isTrue config.modules.system.roles.nas.primary) {
  networking.firewall = {
    enable = true;
    allowPing = true;
  };

  # Discovery.
  services = {
    avahi.enable = true;

    # Network shares.
    samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "log level" = 1;
          "logging" = "systemd";
          "security" = "user";

          "workgroup" = "WORKGROUP";
          "netbios name" = "NAS";

          "server min protocol" = "SMB3";
          "smb encrypt" = "required";
          "client signing" = "mandatory";
          "server signing" = "mandatory";

          "socket options" = "TCP_NODELAY IPTOS_LOWDELAY";
          "use sendfile" = true;

          "hosts deny" = "0.0.0.0/0"; # Deny all by default.
          "hosts allow" = "192.168.86."; # Open to hosts within the local network.
        };

        # Ayako's documents & photos.
        "Ayako Documents" = {
          path = "/tank/ayako/files";
          comment = "Serving Ayako's Documents";
          "guest ok" = false;
          "read only" = false;
          "force create mode" = "0660";
          "force directory mode" = "2770";
          "force user" = "ayako";
          "force group" = "users";
        };

        # Ayako's media library.
        "Ayako Media" = {
          path = "/tank/ayako/media";
          comment = "Serving Ayako's Media Library";
          "guest ok" = false;
          "read only" = false;
          "force create mode" = "0660";
          "force directory mode" = "2770";
          "force user" = "ayako";
          "force group" = "users";
        };
      };
    };

    # Advertise shares to Windows hosts.
    samba-wsdd = {
      enable = true;
      openFirewall = true;
    };
  };
}
