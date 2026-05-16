{
  flake.nixosModules.services-ollama = {
    services.ollama = {
      enable = true;
      acceleration = "rocm";
    };
  };
}
