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
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixfmt.enable = true;
            ansible-lint = {
              enable = true;
              settings = {
                configPath = "./ansible/ansible-lint";
                subdir = "./ansible";
              };
            };
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
            opentofu
            ansible
            ansible-lint
            glab
            vault

            # Precommit stuff
            pre-commit
            gitleaks
            tflint
          ];

          TF_STATE_NAME = "default";
        };
      }
    );
}
