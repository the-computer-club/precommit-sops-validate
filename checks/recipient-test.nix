# file: checks/testEnv.nix
{lib, stdenv, age, sops, git, sops-precommit-hook}:
stdenv.mkDerivation {
  name = "sops-precommit-test-env";
  version = "1.0.0";

  nativeBuildInputs = [
    age
    sops
    git
  ];

  unpackPhase = "true";

  buildPhase = ''
    # Generate test AGE keys
    age-keygen -o test-key-1
    age-keygen -o test-key-2

    # Extract public keys
    grep "public key:" test-key-1 | cut -d: -f2 | tr -d ' ' > test-key-1.pub
    grep "public key:" test-key-2 | cut -d: -f2 | tr -d ' ' > test-key-2.pub

    # Create secrets directory
    mkdir -p secrets

    # Create .sops.yaml config with correct format (string, not list)
    cat > .sops.yaml << EOF
    creation_rules:
      - path_regex: secrets/valid\.json$
        age: $(cat test-key-1.pub)
      - path_regex: secrets/invalid\.json$
        age: $(cat test-key-2.pub)
    EOF

    # Create valid secret (encrypted with key-1, matches config)
    echo '{"database_password": "super-secret-123", "api_key": "test-api-key"}' > valid-plain.json
    SOPS_AGE_KEY_FILE=./test-key-1 sops --filename-override secrets/valid.json --encrypt valid-plain.json > secrets/valid.json

    # Create invalid secret (encrypted with key-1 but config expects key-2)
    echo '{"other_secret": "another-secret-456", "token": "invalid-token"}' > invalid-plain.json
    SOPS_AGE_KEY_FILE=./test-key-1 sops --filename-override secrets/invalid.json --encrypt invalid-plain.json > secrets/invalid.json

    # Initialize git repository
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
    git add .
    git commit -m "Initial test setup"

    # Create test script
    cat > test-hook.sh << 'EOF'
    #!/usr/bin/env bash
    set -e

    echo "=== SOPS Pre-commit Hook Test ==="
    echo ""
    echo "Current configuration (.sops.yaml):"
    cat .sops.yaml
    echo ""

    echo "Current secret recipients:"
    echo "valid.json recipients:"
    sops --decrypt --extract '["sops"]["age"]' secrets/valid.json 2>/dev/null || echo "  Could not extract recipients"
    echo "invalid.json recipients:"
    sops --decrypt --extract '["sops"]["age"]' secrets/invalid.json 2>/dev/null || echo "  Could not extract recipients"
    echo ""

    echo "Running SOPS pre-commit hook..."
    sops-precommit-hook --ed25519-key ./test-key-1 --verbose || true
    echo ""

    echo "After hook execution:"
    echo "valid.json recipients:"
    sops --decrypt --extract '["sops"]["age"]' secrets/valid.json 2>/dev/null || echo "  Could not extract recipients"
    echo "invalid.json recipients:"
    sops --decrypt --extract '["sops"]["age"]' secrets/invalid.json 2>/dev/null || echo "  Could not extract recipients"
    EOF

    chmod +x test-hook.sh

    # Cleanup temporary files
    rm -f valid-plain.json invalid-plain.json test-key-*.pub
  '';

  installPhase = ''
    mkdir -p $out
    cp -r . $out/
  '';

  meta = with lib; {
    description = "SOPS pre-commit hook test environment";
    license = licenses.mit;
  };
}
