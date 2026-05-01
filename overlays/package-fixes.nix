# overlay to fix failing package builds
{
  package-fixes = final: prev: {
    # fails to build due to failing checks
    # https://github.com/NixOS/nixpkgs/issues/513245
    openldap = prev.openldap.overrideAttrs (_: {
      doCheck = false;
    });

    # hash mismatch
    wireshark = prev.wireshark.overrideAttrs (_: {
      src = prev.fetchFromGitLab {
        repo = "wireshark";
        owner = "wireshark";
        tag = "v4.6.5";
        hash = "sha256-Zvrwxjp4LK2J3QnxmPxKKrU01YHQvPyp54UWzeGNCjA=";
      };
    });
  };
}
