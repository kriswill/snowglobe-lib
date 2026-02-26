{ inputs }:
{
  packaged-configs = inputs.dotfiles.overlays.packaged-configs;

  helper-scripts = inputs.dotfiles.overlays.scripts;

  packages =
    final: prev:
    import ../packages {
      pkgs = final;
    };

  awww-git = inputs.awww.overlays.default;
  nh-git = inputs.nh.overlays.default;
  niri-git = inputs.niri.overlays.default;
  prismlauncher-git = inputs.prismlauncher.overlays.default;
  yazi-git = inputs.yazi.overlays.default;

  zsh-syntax-highlighting-fix =
    final: prev: (import ./zsh-syntax-highlighting.nix { inherit final prev; });
}
