{ inputs, ... }:
{
  awww = inputs.awww.overlays.default;
  niri = inputs.niri.overlays.default;
  quickshell = inputs.quickshell.overlays.default;
  custom-neovims = inputs.vim-config.overlays.default;
  prismlauncher = inputs.prismlauncher.overlays.default;
  ghostty = inputs.ghostty.overlays.default;
  # latest disko
  disko = final: prev: {
    disko = inputs.disko.packages.${prev.system}.default;
  };

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
