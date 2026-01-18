{ flake, ... }:
{
  imports = [ flake.modules.nixos.hardware-gpu-common ];
}
