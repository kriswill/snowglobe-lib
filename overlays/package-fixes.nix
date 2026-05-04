# overlay to fix failing package builds
{
  package-fixes = final: prev: {
    # fails to build due to failing checks
    # https://github.com/NixOS/nixpkgs/issues/513245
    openldap = prev.openldap.overrideAttrs (_: {
      doCheck = false;
    });

    ani-cli = prev.ani-cli.overrideAttrs (_: {
      version = "4.14.0";
      src = prev.fetchFromGitHub {
        repo = "ani-cli";
        owner = "pystardust";
        rev = "master";
        hash = "sha256-OyCKDN89sBz59+3JncMDyNOq8UMqqjara+A0Owo3oko=";
      };

      runtimeInputs = prev.ani-cli.runtimeInputs ++ [ prev.libressl ];
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
