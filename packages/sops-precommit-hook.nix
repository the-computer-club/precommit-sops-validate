# file: packages/sops-precommit-hook.nix
{lib, buildPythonApplication, makeWrapper, pyyaml, sops, ssh-to-age, setuptools, git}:
buildPythonApplication rec {
  pname = "sops-precommit-hook";
  version = "1.0.0";

  src = ./.;

  propagatedBuildInputs = [
    pyyaml
  ];

  nativeBuildInputs = [
    makeWrapper
  ];

  buildInputs = [
    sops
    ssh-to-age
    git
  ];

  build-system = [ setuptools ];
  pyproject = true;

  postInstall = ''
    mkdir -p $out/bin
    cp ${../sops-precommit-hook} $out/bin/sops-precommit-hook
    chmod +x $out/bin/sops-precommit-hook

    wrapProgram $out/bin/sops-precommit-hook \
      --prefix PATH : ${lib.makeBinPath [
        git
        sops
        ssh-to-age
      ]}
  '';

  meta = with lib; {
    description = "SOPS pre-commit hook for validating and re-encrypting secrets";
    license = licenses.mit;
    maintainers = [ ];
  };
}
