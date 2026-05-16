{ final, prev }:
{
  # fails to build due to failing checks for the i686 version of the package
  # https://github.com/NixOS/nixpkgs/issues/513245
  openldap = prev.openldap.overrideAttrs (_: {
    doCheck = !prev.stdenv.hostPlatform.isi686;
  });

  # version from nixpkgs fails to download media
  # https://github.com/pystardust/ani-cli/issues/1688
  ani-cli = prev.ani-cli.overrideAttrs (_: {
    version = "4.14.0";
    src = prev.fetchFromGitHub {
      repo = "ani-cli";
      owner = "pystardust";
      rev = "6803b8a15faafa41cb79271e9a4f7f9c70a53651";
      hash = "sha256-OyCKDN89sBz59+3JncMDyNOq8UMqqjara+A0Owo3oko=";
    };

    runtimeInputs = prev.ani-cli.runtimeInputs ++ [ prev.libressl ];
  });

  # labwc from nixpkgs does not include the new labwc-session.target for systemd
  labwc = prev.labwc.overrideAttrs (_: rec {
    version = "0.9.5";
    src = prev.fetchFromGitHub {
      owner = "labwc";
      repo = "labwc";
      rev = "8473ea4b722b7f255590078ac9868538d853f5dd";
      hash = "sha256-0JfOhTDAS7la6OGWPCOmFShLI+d8ThYXfh1dXhQ8M5M=";
    };

    # replace wlroots 0.19 with 0.20
    buildInputs = (prev.lib.remove prev.wlroots_0_19 (prev.labwc.buildInputs)) ++ [
      prev.wlroots_0_20
    ];

    patches = [ ./labwc-meson-build.patch ];
  });

  # fix the symlinks in zsh-syntax-highlighting
  zsh-syntax-highlighting = prev.zsh-syntax-highlighting.overrideAttrs {
    installPhase = ''
      PLUGIN_DIR="$out/share/zsh/plugins/zsh-syntax-highlighting"
      mkdir -p "$PLUGIN_DIR/highlighters"
      cp -r ./highlighters/* "$PLUGIN_DIR/highlighters"
      for link in $(find "$PLUGIN_DIR" -type l); do
        rm "$link"
      done

      install -D zsh-syntax-highlighting.plugin.zsh \
        "$PLUGIN_DIR/zsh-syntax-highlighting.plugin.zsh"
      install -D zsh-syntax-highlighting.zsh \
        "$PLUGIN_DIR/zsh-syntax-highlighting.zsh"
      install -D .revision-hash \
        "$PLUGIN_DIR/.revision-hash"
      install -D .version \
        "$PLUGIN_DIR/.version"

      ln -s "$PLUGIN_DIR" $out/share/zsh-syntax-highlighting
    '';
  };

  # give btop cuda and rocm support
  btop = prev.btop.override {
    rocmSupport = true;
    cudaSupport = true;
  };
}
