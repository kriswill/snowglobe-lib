{ inputs }:
{
  packaged-configs = inputs.dotfiles.overlays.packaged-configs;

  helper-scripts = inputs.dotfiles.overlays.scripts;

  disko-git = final: prev: {
    disko = inputs.disko.packages.${prev.stdenv.hostPlatform.system}.default;
  };

  nixos-anywhere-git = final: prev: {
    nixos-anywhere = inputs.nixos-anywhere.packages.${prev.stdenv.hostPlatform.system}.default;
  };

  rmpc-git = final: prev: {
    rmpc = inputs.rmpc.packages.${prev.stdenv.hostPlatform.system}.default;
  };

  awww-git = inputs.awww.overlays.default;
  ghostty-git = inputs.ghostty.overlays.default;
  nh-git = inputs.nh.overlays.default;
  niri-git = inputs.niri.overlays.default;
  prismlauncher-git = inputs.prismlauncher.overlays.default;
  yazi-git = inputs.yazi.overlays.default;

  zsh-syntax-highlighting-fix =
    final: prev: (import ./zsh-syntax-highlighting.nix { inherit final prev; });

  packages =
    final: prev:
    import ../packages {
      pkgs = final;
    };
}
