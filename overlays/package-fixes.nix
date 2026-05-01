# overlay to fix failing package builds
{
  package-fixes = final: prev: {
    # fails to build due to failing checks
    # https://github.com/NixOS/nixpkgs/issues/513245
    openldap = prev.openldap.overrideAttrs (_: {
      doCheck = false;
    });
  };
}
