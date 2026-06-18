{
  nixpkgs-stable,
  final,
  prev,
}:
{
  freetube = prev.freetube.overrideAttrs (finalAttrs: {
    version = "0.24.1";
    src = prev.fetchFromGitHub {
      owner = "FreeTubeApp";
      repo = "FreeTube";
      tag = "v${finalAttrs.version}-beta";
      hash = "sha256-oo5ozdP3d82jY8OOYrt568MoSfPmwBoitdtgESiRMlE=";
    };

    yarnOfflineCache = prev.fetchYarnDeps {
      yarnLock = "${finalAttrs.src}/yarn.lock";
      hash = "sha256-9rO/XYfOf1TEQOpb5clCfdTiuDeynpnk6L4WpcIIWGk=";
    };

    patches =
      let
        replaceVars = prev.replaceVars;
      in
      [
        (replaceVars ./freetube-build-script.patch {
          electron-version = prev.electron.version;
        })
        ./freetube-targets.patch
      ];
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

  # puddletag's icon is located in the wrong spot.
  # This causes some programs to display an empty icon entry
  puddletag = prev.puddletag.overrideAttrs (_: {
    postFixup = ''
      ICON_DIR=$out/share/icons/hicolor/256x256/apps
      mkdir -p $ICON_DIR
      mv $out/share/icons/puddletag.png $ICON_DIR
    '';
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
