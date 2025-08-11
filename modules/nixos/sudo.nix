{
  security.pam = {
    sshAgentAuth.enable = true;
    services.sudo.sshAgentAuth = true;
    # services.login.sshAgentAuth = true;
  };

  users.users.delay.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFxNtcVPBB691syv5AvWu5NdZWDkki2GisIQJSitSwSV sudo"
  ];
}
