{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, utils }: utils.lib.eachDefaultSystem (system:
    let
      linuxSystem = "x86_64-linux";
      pkgs = import nixpkgs { system = "x86_64-linux"; config.allowUnfree = true; };
    in
    {
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          terraform
        ];
      };
    }
  );
}
