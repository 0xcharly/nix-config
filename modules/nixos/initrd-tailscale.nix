{
  config,
  lib,
  pkgs,
  ...
}: {
  options.node.boot.initrd.tailscale = with lib; {
    authKeyFile = mkOption {
      type = types.path;
      default = config.age.secrets."services/tailscale-preauth-initrd.key".path;
      description = ''
        The path to the file containing the Tailscale auth key.
      '';
    };
  };

  config.boot = let
    cfg = config.node.boot.initrd.tailscale;

    iptables-static = pkgs.iptables.overrideAttrs (old: {
      dontDisableStatic = true;
      configureFlags =
        (lib.remove "--enable-shared" old.configureFlags)
        ++ [
          "--enable-static"
          "--disable-shared"
        ];
    });

    # Undo https://github.com/NixOS/nixpkgs/pull/306532.
    tailscale-wrapped = pkgs.tailscale.overrideAttrs (oldAttrs: {
      subPackages = oldAttrs.subPackages ++ ["cmd/tailscale"];
      postInstall = ''
        wrapProgram $out/bin/tailscaled --prefix PATH : ${
          lib.makeBinPath (with pkgs; [
            iproute2
            iptables
            getent
            shadow
          ])
        }
        wrapProgram $out/bin/tailscale --suffix PATH : ${lib.makeBinPath [pkgs.procps]}
        moveToOutput "bin/derper" "$derper"
      '';
    });
  in {
    initrd = {
      kernelModules = ["tun"];
      availableKernelModules = [
        "nft_chain_nat"
        "nft_compat"
        "nft_compat"
        "xt_LOG"
        "xt_MASQUERADE"
        "xt_addrtype"
        "xt_comment"
        "xt_conntrack"
        "xt_mark"
        "xt_multiport"
        "xt_pkttype"
        "xt_tcpudp"
      ];

      extraUtilsCommands = ''
        copy_bin_and_libs ${pkgs.iproute2}/bin/ip
        copy_bin_and_libs ${iptables-static}/bin/iptables
        copy_bin_and_libs ${iptables-static}/bin/ip6tables
        copy_bin_and_libs ${iptables-static}/bin/xtables-legacy-multi
        copy_bin_and_libs ${iptables-static}/bin/xtables-nft-multi
        copy_bin_and_libs ${tailscale-wrapped}/bin/.tailscale-wrapped
        copy_bin_and_libs ${tailscale-wrapped}/bin/.tailscaled-wrapped
      '';

      secrets."/etc/tailscale-preauth.key" = cfg.authKeyFile;

      network.postCommands = ''
        .tailscaled-wrapped --state=mem: &
        .tailscale-wrapped up --hostname=${config.networking.hostName}-initrd --auth-key='file:/etc/tailscale-preauth.key' &
      '';
    };
  };
}
