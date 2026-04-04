{ inputs, lib }:
import ./rolling-releases.nix { inherit inputs; }
// import ./self-maintained.nix { inherit lib; }
// {
  helper-scripts = inputs.dotfiles.overlays.scripts;

  # custom packages
  packages =
    final: prev:
    import ../packages {
      pkgs = final;
    };

  packaged-configs = inputs.dotfiles.overlays.packaged-configs;

  zsh-syntax-highlighting-fix =
    final: prev: (import ./zsh-syntax-highlighting.nix { inherit final prev; });
}
