{ config, pkgs, ... }:

{
  imports = [ ./darwin-common.nix ];

  environment.shells = with pkgs; [ fish ];
}
