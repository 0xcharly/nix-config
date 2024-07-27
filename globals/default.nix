{globalModules, ...}: {
  imports = with globalModules; [settings unfree];
}
