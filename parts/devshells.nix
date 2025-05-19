{
  perSystem = {pkgs, ...}: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        alejandra
        cachix
        jq
        just
        lua-language-server
        nixd
        prettierd
        stylua
      ];
    };
  };
}
