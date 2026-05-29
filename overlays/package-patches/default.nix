{
  nixpkgs-stable,
  final,
  prev,
}:
{
  # fails to build due to failing checks for the i686 version of the package
  # https://github.com/NixOS/nixpkgs/issues/513245
  openldap = prev.openldap.overrideAttrs (_: {
    doCheck = !prev.stdenv.hostPlatform.isi686;
  });

  # labwc from nixpkgs does not include the new labwc-session.target for systemd
  # https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/by-name/la/labwc/package.nix#L89
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

  # ani-cli cant download media from version in nixpkgs
  ani-cli = prev.ani-cli.overrideAttrs (_: rec {
    version = "4.14.1";
    src = prev.fetchFromGitHub {
      owner = "pystardust";
      repo = "ani-cli";
      rev = "b8032b72901721a1ce859ca2816e8e2c914bc616";
      hash = "sha256-+fR46bWXJ58LkXFvWAO/LyCd5THi7oMcqmhRoCKBZfM=";
    };
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
