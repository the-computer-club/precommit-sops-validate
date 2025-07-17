# Usage Example 1: With flake-parts
flake.nix in your project
```nix
{
  description = "My project with SOPS secrets";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-precommit = {
      url = "github:the-computer-club/sops-precommit-hook";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake 
    { inherit inputs; }
    {
      imports = [
        inputs.git-hooks.flakeModule
        inputs.sops-precommit.flakeModule
      ];

      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      perSystem = { config, self', inputs', pkgs, system, ... }: {
        pre-commit = {
          check.enable = true;
          settings.hooks = {
            # Standard hooks
            nixpkgs-fmt.enable = true;
            deadnix.enable = true;
            sops-precommit = {
              enable = true;
              settings.ed25519KeyPath = "/path/to/your/key";  # Optional: override default (/etc/ssh/host_ed25519_key (private))
              settings.verbose = true;                        # Optional: enable verbose logging
              settings.pgpKey = "your-pgp-fingerprint";       # Optional: PGP key
              settings.extraArgs = [ "--some-extra-arg" ];    # Optional: additional arguments
            };
          };
        };
      };
    };
}
```



