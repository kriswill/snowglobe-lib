{ inputs, ... }:
{
  awww = inputs.awww.overlays.default;
  niri = inputs.niri.overlays.default;
  quickshell = inputs.quickshell.overlays.default;
  dotfiles-packaged-configs = inputs.dotfiles.overlays.default;
  prismlauncher = inputs.prismlauncher.overlays.default;
  ghostty = inputs.ghostty.overlays.default;
  disko = final: prev: {
    disko = inputs.disko.packages.${prev.stdenv.hostPlatform.system}.default;
  };
  yazi = inputs.yazi.overlays.default;

  packages =
    final: prev:
    import ./packages {
      inherit inputs;
      pkgs = final;
    };

  disable-mbrola-voices = final: prev: {
    espeak = prev.espeak.override {
      mbrolaSupport = false;
    };
  };
}
