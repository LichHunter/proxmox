{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, utils }: utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { system = system; config.allowUnfree = true; };
    in
    {
      devShell = pkgs.mkShell {
        packages = with pkgs; [
          pyenv
          uv
          ansible
          ansible-lint
        ];
      };
    }
  );
}
