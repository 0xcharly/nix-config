{
  config,
  lib,
  ...
}: {
  options.node.services.postgresql = with lib; {
    enable =
      mkEnableOption "Sets up ZFS datasets and postgresql options"
      // {
        default = config.services.postgresql.enable;
      };
  };

  config = let
    cfg = config.node.services.postgresql;
  in {
    assertions = [
      {
        assertion = config.services.postgresql.enable -> cfg.enable;
        message = "Enable custom postgresql module to finetune filesystem and options";
      }
    ];
  };
}
