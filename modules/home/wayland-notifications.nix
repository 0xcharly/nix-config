{ inputs, ... }:
{
  imports = [ inputs.nix-config-colorscheme.modules.home.fish ];

  services.mako = {
    enable = true;
    settings = {
      anchor = "top-right";
      default-timeout = 5000;
      width = 420;
      height = 110;
      margin = 8;

      "app-name=Tidal".invisible = true;
      "mode=do-not-disturb".invisible = true;
      "mode=do-not-disturb app-name=notify-send".invisible = false;
      "urgency=critical".default-timeout = 0;
    };
  };
}
