{ inputs }:
{
  awww-git = inputs.awww.overlays.default;

  disko-git = final: prev: {
    disko = inputs.disko.packages.${prev.stdenv.hostPlatform.system}.default;
  };

  ghostty-git = inputs.ghostty.overlays.default;

  helper-scripts = inputs.dotfiles.overlays.scripts;

  lutris-git =
    final: prev:
    import ../packages/self-maintained/lutris {
      pkgs = final;
    };

  manga-tui-git = final: prev: {
    manga-tui = inputs.manga-tui.packages.${prev.stdenv.hostPlatform.system}.default;
  };

  nh-git = inputs.nh.overlays.default;

  niri-git = inputs.niri.overlays.default;

  nixos-anywhere-git = final: prev: {
    nixos-anywhere = inputs.nixos-anywhere.packages.${prev.stdenv.hostPlatform.system}.default;
  };

  packages =
    final: prev:
    import ../packages {
      pkgs = final;
    };

  packaged-configs = inputs.dotfiles.overlays.packaged-configs;

  prismlauncher-git = inputs.prismlauncher.overlays.default;

  rmpc-git = final: prev: {
    rmpc = inputs.rmpc.packages.${prev.stdenv.hostPlatform.system}.default;
  };

  yazi-git = inputs.yazi.overlays.default;

  zsh-syntax-highlighting-fix =
    final: prev: (import ./zsh-syntax-highlighting.nix { inherit final prev; });

}
