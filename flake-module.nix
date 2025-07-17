# file: sops-precommit-hook
{ flake-parts-lib, lib, ... }:
{
  options = {
    perSystem = flake-parts-lib.mkPerSystemOption ({ config, self', inputs', pkgs, system, ... }: {
      options.pre-commit.settings.hooks.sops-validator.settings = {
        ed25519KeyPath = lib.mkOption {
          type = lib.types.str;
          default = "/etc/ssh/ssh_host_ed25519_key";
          description = "Path to ED25519 SSH key for decryption";
        };

        pgpKey = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "PGP key fingerprint for decryption";
        };

        filePattern = lib.mkOption {
          type = lib.types.str;
          default = "\\.(yaml|yml|json|env|keytab)$";
          description = "File pattern to match for SOPS validation";
        };

        verbose = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable verbose logging";
        };

        extraArgs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Extra arguments to pass to the SOPS pre-commit hook";
        };
      };
    });
  };

  config = {
    perSystem = { config, self', inputs', pkgs, system, ... }:
      let
        cfg = config.sops-precommit;
        buildHookArgs =
          [ "--ed25519-key" cfg.ed25519KeyPath ] ++
          (if cfg.pgpKey != null then [ "--pgp-key" cfg.pgpKey ] else []) ++
          (if cfg.verbose then [ "--verbose" ] else []) ++
          cfg.extraArgs;
      in
      {
        precommit.settings.hooks.sops-validate = {
          enable = true;
          name = "SOPS Secrets Validation";
          description = "Validate and re-encrypt SOPS secrets based on configuration";
          entry = "${self'.packages.sops-precommit-hook}/bin/sops-precommit-hook";
          files = cfg.filePattern;
          language = "system";
          pass_filenames = false;
          require_serial = true;
          args = buildHookArgs;
        };
      };
  };
}
