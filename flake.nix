{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks.url = "github:cachix/git-hooks.nix";
    deploy-rs.url = "github:serokell/deploy-rs";
    sops-nix.url = "github:Mic92/sops-nix";
    nixarr.url = "git+ssh://gitea@gitea.susano-homelab.duckdns.org/fujin/nixarr.git";
    copyparty.url = "github:9001/copyparty";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-parts,
      git-hooks,
      deploy-rs,
      sops-nix,
      nixarr,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        {
          system,
          ...
        }:
        let
          pkgs = import nixpkgs {
            inherit system;
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
            };
          };

          lxcSystem = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [ ./templates/lxc-base.nix ];
          };
        in
        {
          formatter = pkgs.nixfmt-tree;

          checks = {
            inherit pre-commit-check;
          };

          packages.lxc-template = lxcSystem.config.system.build.tarball;

          devShells.default = pkgs.mkShell {
            inherit (pre-commit-check) shellHook;

            buildInputs = with pkgs; [
              opentofu
              ansible
              ansible-lint
              glab
              vault
              python3Packages.hvac
              yq
              sops
              age
              ssh-to-age

              # Precommit stuff
              pre-commit
              gitleaks
              tflint

              opencode
            ];

            TF_STATE_NAME = "default";
          };
        };

      flake = {
        nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [ ./machines/nixos/nixarr ];
        };

        deploy.nodes.nixarr = {
          hostname = "192.168.1.54";
          profiles.system = {
            user = "root";
            sshUser = "root";
            sshOpts = [
              "-o"
              "StrictHostKeyChecking=no"
              "-i"
              ".secrets/nixarr_key"
            ];
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nixos;
          };
        };
      };
    };
}
