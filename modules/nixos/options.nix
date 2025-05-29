{lib, ...}: {
  options.isNixOS = lib.options.mkOption {
    type = lib.types.bool;
    default = true;
    readOnly = true;
    description = ''
      A flag allowing to distinguish between HM running on NixOS and
      standalone HM setups.
    '';
  };
}
