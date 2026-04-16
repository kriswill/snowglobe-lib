{ inputs, lib }:
import ./rolling-releases.nix { inherit inputs; }
// import ./self-maintained.nix { inherit lib; }
// {
  # custom packages
  packages =
    final: prev:
    import ../packages {
      pkgs = final;
    };

  zsh-syntax-highlighting-fix =
    final: prev: (import ./zsh-syntax-highlighting.nix { inherit final prev; });

  nix-post-build-hook-queue = inputs.nix-post-build-hook-queue.overlays.default;
}
