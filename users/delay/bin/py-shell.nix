let
  pkgs = import <nixpkgs> {};
in
  pkgs.mkShell {
    packages = [
      (pkgs.python312.withPackages (python-pkgs: [
        python-pkgs.bcrypt
        python-pkgs.cryptography
        python-pkgs.pylint
        python-pkgs.python-lsp-black
        python-pkgs.python-lsp-server
      ]))
    ];
  }
