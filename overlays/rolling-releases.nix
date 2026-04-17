{ inputs, ... }:
{
  awww-git = inputs.awww.overlays.default;

  disko-git = final: prev: {
    disko = inputs.disko.packages.${prev.stdenv.hostPlatform.system}.default;
  };

  ghostty-git = inputs.ghostty.overlays.default;
  # TODO this flake's package is broken
  # manga-tui-git = final: prev: {
  #   manga-tui = inputs.manga-tui.packages.${prev.stdenv.hostPlatform.system}.default;
  # };

  nh-git = inputs.nh.overlays.default;

  niri-git = inputs.niri.overlays.default;

  prismlauncher-git = inputs.prismlauncher.overlays.default;

  rmpc-git = final: prev: {
    rmpc = inputs.rmpc.packages.${prev.stdenv.hostPlatform.system}.default;
  };

  yazi-git = inputs.yazi.overlays.default;
}
