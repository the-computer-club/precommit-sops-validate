# file: flake.nix
{
  description = "SOPS pre-commit hook flake module";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";

  outputs = inputs@{flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; }
    {
      systems = [ "x86_64-linux" ];
      # The flake module
      flake.flakeModule = ./flake-module.nix;

      # Standalone packages for direct use
      perSystem = {config, pkgs, ...}: {
        packages.default = config.packages.sops-precommit-hook;
        packages.sops-precommit-hook = pkgs.python3Packages.callPackage
          ./packages/sops-precommit-hook.nix {};

        packages.testEnv =
          pkgs.python3Packages.callPackage
          ./checks/recipient-test.nix {
            inherit (config.packages) sops-precommit-hook;
          };

        checks.testEnv = config.packages.testEnv;

        devShells.sops-precommit = pkgs.mkShell {
          buildInputs = with pkgs; [
            (python3.withPackages (ps: with ps; [pyyaml]))
            sops
            ssh-to-age
            git
            config.packages.sops-precommit-hook
          ];

          shellHook = ''
            echo "SOPS pre-commit development environment"
            echo "Available commands:"
            echo "  sops-precommit-hook - Run the SOPS validation hook"
          '';
        };

        apps.sops-validate = {
          type = "app";
          program = "${config.packages.sops-precommit-hook}/bin/sops-precommit-hook";
        };
      };
    };
}
