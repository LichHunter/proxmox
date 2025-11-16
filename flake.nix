{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    utils.url = "github:numtide/flake-utils";
    git-hooks.url = "github:cachix/git-hooks.nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      utils,
      git-hooks,
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        linuxSystem = "x86_64-linux";
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt.enable = true;
            ansible-lint.enable = true;
            tflint.enable = true;
            terraform-format.enable = true;
            terraform-validate.enable = true;
          };
        };
      in
      {
        checks = {
          inherit pre-commit-check;
        };

        devShell = pkgs.mkShell {
          inherit (pre-commit-check) shellHook;

          buildInputs = with pkgs; [
            terraform
            ansible
            ansible-lint

            # Precommit stuff
            pre-commit
            gitleaks
            tflint
          ];
        };
      }
    );
}
