{
  writeShellApplication,
  scrcpy,
}:
writeShellApplication {
  name = "raycast-scrcpy";
  runtimeInputs = [scrcpy];
  text = builtins.readFile ./raycast-scrcpy.sh;
}
