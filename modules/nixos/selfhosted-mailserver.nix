{ flake, inputs, ... }:
{
  config,
  lib,
  ...
}:
{
  imports = [
    inputs.simple-nixos-mailserver.nixosModule
  ];

  options.node.services.mailserver = with lib; {
    enable = mkEnableOption "a self-hosted, private mailserver";
  };

  config =
    let
      cfg = config.node.services.mailserver;
      inherit (flake.lib) facts;
    in
    {
      disko.devices.zpool.root.datasets = {
        mail = flake.lib.zfs.mkLegacyDataset "/var/mail/boxes" {
          recordsize = "16K"; # Maildir files are small (often 1–50KB)
          compression = "lz4"; # Emails compress extremely well (headers + text)
          atime = "off"; # Metadata savings for IMAP access
          xattr = "sa"; # Faster metadata (when Dovecot uses xattrs)
          acltype = "posixacl";
          dnodesize = "auto"; # Helps with lots of small files and metadata density
          logbias = "latency"; # Mail delivery is sync-heavy (fsync on every mail)
        };
        # Indexes are disposable cache
        # Extremely write-heavy
        # Small random I/O
        # Safe to lose / rebuildable
        index = flake.lib.zfs.mkLegacyDataset "/var/mail/index" {
          recordsize = "16K"; # Mixed workload: small regular + large FTS indexes
          compression = "lz4";
          atime = "off";
          sync = "disabled"; # Indexes are disposable
          primarycache = "metadata"; # Prevents index blobs from evicting useful ARC data (low RAM VPS)
          logbias = "throughput"; # Indexes are not latency-critical
        };
        # Small files rarely written.
        sieve = flake.lib.zfs.mkLegacyDataset "/var/mail/sieve" {
          recordsize = "16K";
          compression = "lz4";
          atime = "off";
        };
        # Tiny private keys with high entropy. Small recordsize avoids read amplification.
        dkim = flake.lib.zfs.mkLegacyDataset "/var/mail/dkim" {
          recordsize = "4K";
          compression = "off";
          atime = "off";
        };
      };

      services.mailserver = {
        inherit (cfg) enable;
        stateVersion = 3;

        inherit (facts.mail) domains;
        inherit (facts.mail.bastion) mx;

        loginAccounts = {
          "delay" = {
            hashedPasswordFile = config.age.secrets."services/mail/delay.passwd".path;
            # catchAll.
            # @example.com allows sending from all email addresses in that domain.
            aliases = map (domain: "@${domain}") facts.mail.domains;
            # catchAll = facts.mail.domains;
          };
        };

        indexDir = "/var/mail/index";
        fullTextSearch = {
          enable = true;
          languages = [
            "en"
            "fr"
            "jp"
          ];
        };

        vmailUID = 3000;
        vmailUserName = "mail";
        vmailGroupName = "mail";
        mailDirectory = "/var/mail/boxes";

        sieveDirectory = "/var/mail/sieve";
        dkimKeyDirectory = "/var/mail/dkim";

        useUTF8FolderNames = true;
        hierarchySeparator = "/";

        enableImapSsl = true;
        enableSubmissionSsl = true;
      };
    };
}
