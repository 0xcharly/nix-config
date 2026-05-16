{
  flake.nixosModules.services-fail2ban = {
    # SSH rules systematically enabled
    services.fail2ban.enable = true;
  };
}
