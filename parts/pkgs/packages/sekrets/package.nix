{
  lib,
  pkgs,
}: let
  writePython312 = pkgs.writers.makePythonWriter pkgs.python312 pkgs.python312Packages pkgs.buildPackages.python312Packages;
  writePython312Bin = name: writePython312 "/bin/${name}";

  sekrets = writePython312Bin "sekrets" {
    libraries = with pkgs.python312Packages; [
      bcrypt
      cryptography
      rich
    ];
    flakeIgnore = ["E501"]; # Line length.
  } (builtins.readFile ./sekrets.py);
in
  pkgs.writeShellApplication {
    name = "sekrets";
    runtimeInputs = [pkgs._1password-cli];
    text = ''
      ${lib.getExe sekrets} "$@"
    '';
  }
# TODO: Do we want to convert this into a poetry project?
# {
#   lib,
#   buildPythonPackage,
#   # Build dependencies.
#   poetry-core,
#   setuptools,
#   setuptools-scm,
#   # Runtime dependencies.
#   bcrypt,
#   cryptography,
#   rich,
#   typing-extensions,
#   # Sanity checks.
#   pytestCheckHook,
# }: let
#   _0xcharly = {
#     name = "Charly Delay";
#     email = "charly@delay.gg";
#     github = "0xcharly";
#     githubId = 5804569;
#   };
# in
#   buildPythonPackage {
#     pname = "sekrets";
#     version = "0.1.0";
#     pyproject = true;
#
#     src = ./.;
#
#     build-system = [
#       poetry-core
#       setuptools
#       setuptools-scm
#     ];
#
#     dependencies = [
#       bcrypt
#       cryptography
#       rich
#       typing-extensions
#     ];
#
#     # Has no tests.
#     doCheck = false;
#
#     nativeCheckInputs = [pytestCheckHook];
#
#     meta = {
#       description = "Utility script to manipulate personal vault and stored secrets.";
#       license = lib.licenses.mit;
#       maintainers = [_0xcharly];
#     };
#   }

